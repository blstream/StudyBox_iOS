//
//  CollectionReusableFilterView.swift
//  StudyBox_iOS
//
//  Created by Damian Malarczyk on 27.05.2016.
//  Copyright © 2016 BLStream. All rights reserved.
//

import UIKit


class CollectionReusableFilterView: UICollectionReusableView {
    
    @IBOutlet weak var filterButton: UIButton!
    var filterAction: ((sender: UIButton, completion: (String) -> ()) ->  ())?
    
    
    @IBAction func filterButtonTouch(sender: UIButton) {
        filterAction?(sender: sender) { [weak self] newTitle in
            self?.filterButton.setTitle(newTitle, forState: .Normal)
        }
    }
    
}
