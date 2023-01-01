//
//  DetailViewController.swift
//  Favgame
//
//  Created by deri indrawan on 28/12/22.
//

import UIKit
import Combine
import SkeletonView
import Favgame_Core

public class DetailViewController: UIViewController {
  // MARK: - Properties
  var getGameDetailUseCase: GetGameDetailUseCase?
  var checkIsFavoriteUseCase: CheckIsFavoriteUseCase?
  var insertFavoriteGameUseCase: InsertFavoriteGameUseCase?
  var deleteFavoriteGameUseCase: DeleteFavoriteGameUseCase?
  private var cancellables: Set<AnyCancellable> = []
  private var gameDetail: GameDetail?
  private var gameId: Int?
  private var isFavorite: Bool = false
  
  private let detailCollectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    layout.minimumInteritemSpacing = 0
    layout.minimumLineSpacing = 0
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    collectionView.isSkeletonable = true
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.register(
      DetailHeaderView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: DetailHeaderView().identifier
    )
    collectionView.register(
      DetailDesccriptionCollectionViewCell.self,
      forCellWithReuseIdentifier: DetailDesccriptionCollectionViewCell().identifier
    )
    return collectionView
  }()
  
  lazy var favoriteButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "heart"), for: .normal)
    button.tintColor = .systemRed
    button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    return button
  }()
  
  // MARK: - Life Cycle
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    checkFavorite()
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(rgb: Constant.rhinoColor)
    self.tabBarController?.tabBar.isHidden = true
    
    let button = UIButton(type: .system)
    button.setTitle("Back", for: .normal)
    button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: favoriteButton)
    
    fetchGameDetail()
    setupUI()
  }
  
  // MARK: - Selector
  @objc private func backButtonTapped() {
    dismiss(animated: true)
  }
  
  @objc private func favoriteButtonTapped() {
    if isFavorite {
      isFavorite = false
      favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
      navigationItem.rightBarButtonItem = UIBarButtonItem(customView: favoriteButton)
      deleteFromFavorite()
    } else {
      isFavorite = true
      favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
      navigationItem.rightBarButtonItem = UIBarButtonItem(customView: favoriteButton)
      insertToFavorite()
    }
  }
  
  // MARK: - Helper
  private func setupUI() {
    view.addSubview(detailCollectionView)
    detailCollectionView.anchor(
      top: view.topAnchor,
      leading: view.leadingAnchor,
      bottom: view.bottomAnchor,
      trailing: view.trailingAnchor
    )
    detailCollectionView.delegate = self
    detailCollectionView.dataSource = self
  }
  
  private func fetchGameDetail() {
    guard let gameId = gameId else { return }
    getGameDetailUseCase?.execute(withGameId: gameId)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure:
          let alert = UIAlertController(title: "Alert", message: String(describing: completion), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self.present(alert, animated: true)
        case .finished:
          self.detailCollectionView.reloadData()
        }
      }, receiveValue: { gameDetail in
        self.gameDetail = gameDetail
      })
      .store(in: &cancellables)
  }
  
  private func checkFavorite() {
    guard let id = self.gameId else { return }
    checkIsFavoriteUseCase?.execute(withGameId: id)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure:
          let alert = UIAlertController(title: "Alert", message: String(describing: completion), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self.present(alert, animated: true)
        case .finished:
          print("checkFavorite has been called")
        }
      }, receiveValue: { isFavorite in
        self.isFavorite = isFavorite
        if isFavorite {
          self.favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
          self.favoriteButton.addTarget(self, action: #selector(self.favoriteButtonTapped), for: .touchUpInside)
          self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.favoriteButton)
        } else {
          self.favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
          self.favoriteButton.addTarget(self, action: #selector(self.favoriteButtonTapped), for: .touchUpInside)
          self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.favoriteButton)
        }
      })
      .store(in: &cancellables)
  }
  
  private func insertToFavorite() {
    guard let gameDetail = gameDetail else { return }
    let game = Game(
      id: gameDetail.id,
      name: gameDetail.name,
      released: gameDetail.released,
      backgroundImage: gameDetail.backgroundImage,
      rating: gameDetail.rating
    )
    insertFavoriteGameUseCase?.execute(with: game)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure:
          let alert = UIAlertController(title: "Alert", message: String(describing: completion), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self.present(alert, animated: true)
        case .finished:
          print("insertToFavorite has been called")
        }
      }, receiveValue: { isSuccess in
        if isSuccess {
          self.sendFavoriteNotification()
          self.isFavorite = true
        }
      })
      .store(in: &cancellables)
  }
  
  private func deleteFromFavorite() {
    guard let gameId = self.gameId else { return }
    deleteFavoriteGameUseCase?.execute(withGamid: gameId)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure:
          let alert = UIAlertController(title: "Alert", message: String(describing: completion), preferredStyle: .alert)
          alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self.present(alert, animated: true)
        case .finished:
          self.sendFavoriteNotification()
        }
      }, receiveValue: { isSuccess in
        if isSuccess {
          self.isFavorite = false
        }
      })
      .store(in: &cancellables)
  }
  
  private func sendFavoriteNotification() {
    NotificationCenter.default.post(name: NSNotification.Name(Constant.favoritePressedNotif), object: nil)
  }
  
  func configure(withGameId id: Int) {
    gameId = id
  }
  
}

extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  // MARK: - UICollectionViewDataSource
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 1
  }
  
  public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: DetailDesccriptionCollectionViewCell().identifier,
      for: indexPath
    ) as? DetailDesccriptionCollectionViewCell else { return UICollectionViewCell() }
    
    if gameDetail != nil {
      cell.configure(with: gameDetail!)
    }
    return cell
  }
  
  // MARK: - UICollectionViewDelegate
  public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    guard let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: DetailHeaderView().identifier,
      for: indexPath
    ) as? DetailHeaderView else { return UICollectionReusableView() }
    
    if gameDetail != nil {
      header.configure(with: gameDetail!)
    }
    
    return header
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: view.frame.width, height: 300)
  }
  
  public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: view.frame.width, height: 1200)
  }
  
}
