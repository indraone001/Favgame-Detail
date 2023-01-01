//
//  DetailRouter.swift
//  Favgame
//
//  Created by deri indrawan on 31/12/22.
//

import Foundation
import Favgame_Core

public class DetailRouter {
  let container: Container = {
    let container = Injection().container
    
    container.register(DetailViewController.self) { resolver in
      let controller = DetailViewController()
      controller.getGameDetailUseCase = resolver.resolve(GetGameDetailUseCase.self)
      controller.insertFavoriteGameUseCase = resolver.resolve(InsertFavoriteGameUseCase.self)
      controller.checkIsFavoriteUseCase = resolver.resolve(CheckIsFavoriteUseCase.self)
      controller.deleteFavoriteGameUseCase = resolver.resolve(DeleteFavoriteGameUseCase.self)
      return controller
    }
    return container
  }()
}

