//
//  DecksViewController+searching.swift
//  StudyBox_iOS
//
//  Created by Damian Malarczyk on 18.05.2016.
//  Copyright © 2016 BLStream. All rights reserved.
//

import UIKit
import Reachability
import SVProgressHUD

extension DecksViewController: UISearchControllerDelegate, UISearchBarDelegate {
    
    func adjustSearchBar(forYOffset offset: CGFloat) {
        if !searchController.active {
            if offset < topItemOffset + topOffset {
                
                searchBarWrapper.frame.origin.y = -offset
                
            } else {
                searchBarWrapper.frame.origin.y = -searchBarHeight
            }
        }
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        adjustSearchBar(forYOffset: offset)
        
    }
    
    func filterOnlineDecks(timer: NSTimer) {
        
        guard Reachability.isConnected() else {
            SVProgressHUD.showErrorWithStatus("Brak połączenia z internetem")
            return
        }
        guard let filter = timer.userInfo?["searchText"] as? String else {
            return
        }
        
        let searchText = filter.trimWhiteCharacters()
        if !searchText.characters.isEmpty && searchText.characters.count <= 100 {
            emptySearch = false 
            let searchBlock = {
                self.searchDecks = self.searchDecksHolder
                    .filter {
                        return $0.0.matches(searchText)
                    }
                self.collectionView?.reloadData()
                
            }
            if searchDecksHolder.isEmpty {
                dataManager.decksWithFlashcardsCount(true) {
                    SVProgressHUD.show()
                    switch $0 {
                    case .Success(let obj):
                        self.searchDecksHolder = self.currentSortingOption.sort(obj)
                        SVProgressHUD.dismiss()
                        searchBlock()
                        
                    case .Error:
                        SVProgressHUD.showErrorWithStatus("Pobranie danych nie było możliwe, spróbuj później")
                    }
                }
            } else {
                searchBlock()
            }
        } else {
            emptySearch = true
            searchDecks = []
            collectionView?.reloadData()
        }
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if let searchDelay = searchDelay {
            searchDelay.invalidate()
        }
        searchDelay = NSTimer(timeInterval: 0.05, target: self,
                              selector: #selector(filterOnlineDecks(_:)), userInfo: ["searchText": searchText], repeats: false)
        searchDelay?.fire()
    }
    
    func willPresentSearchController(searchController: UISearchController) {
        if collectionView?.contentOffset.y > topItemOffset {
            collectionView?.contentOffset.y = topItemOffset
        }
        collectionView?.reloadData()
    }
    
    func willDismissSearchController(searchController: UISearchController) {
        searchDecks = []
        emptySearch = true
        collectionView?.reloadData()
    }
    
    func didDismissSearchController(searchController: UISearchController) {
        searchController.searchBar.sizeToFit()
        searchDecksHolder = []
    }
    
    
}
