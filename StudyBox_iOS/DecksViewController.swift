//
//  DecksViewController.swift
//  StudyBox_iOS
//
//  Created by Kacper Cz, Damian Malarczyk on 03.03.2016.
//  Copyright © 2016 BLStream. All rights reserved.
//
import UIKit
import SVProgressHUD

class DecksViewController: StudyBoxCollectionViewController, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout, DecksCollectionLayoutDelegate {
    
    var searchBarWrapper: UIView!
    var searchBarTopConstraint: NSLayoutConstraint!
    var searchController: UISearchController = UISearchController(searchResultsController: nil)
    let refreshControl = UIRefreshControl()

    var searchBar: UISearchBar {
        return searchController.searchBar
    }
    var currentSortingOption: DecksSortingOption = .CreateDate
    
    var decksArray: [(Deck, Int)] = []
    var searchDecks: [(Deck, Int)] = []
    var searchDecksHolder: [(Deck, Int)] = []
    var searchDelay: NSTimer?
    
    var decksSource: [(Deck, Int)] {
        return searchDecks.isEmpty && !searchController.active ? decksArray : searchDecks
    }
    
    
    lazy var dataManager: DataManager = UIApplication.appDelegate().dataManager

    private var statusBarHeight: CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.height
    }
    
    var searchBarHeight: CGFloat {
       return 44
    }
    
    private var searchBarMargin: CGFloat {
        return 8
    }
    
    private var navbarHeight: CGFloat  {
        return self.navigationController?.navigationBar.frame.height ?? 0
    }
    
    // search bar height + 8 points margin
    var topOffset: CGFloat {
        return self.searchBarHeight + searchBarMargin
    }
    
    private var initialLayout = true
    
    /**
     * CollectionView content offset is determined by status bar and navigation bar height
     */
    var topItemOffset: CGFloat {
        return -(self.statusBarHeight + self.navbarHeight)
    }
    
    func shouldStrech() -> Bool {
        return !searchController.active
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.collectionViewLayout = DecksCollectionViewLayout()
        collectionView?.collectionViewLayout.invalidateLayout()
        if let decksLayout = collectionView?.collectionViewLayout as? DecksCollectionViewLayout {
            decksLayout.delegate = self 
        }
        navigationItem.title = "Moje talie"
        searchBarWrapper = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: searchBarHeight))
        searchBarWrapper.autoresizingMask = .FlexibleWidth
        searchBarWrapper.addSubview(searchBar)
        view.addSubview(searchBarWrapper)
        searchBar.delegate = self
        searchController.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        
        definesPresentationContext = true
        collectionView?.backgroundColor = UIColor.sb_White()
        collectionView?.alwaysBounceVertical = true
        refreshControl.tintColor = UIColor.sb_Graphite()
        refreshControl.addTarget(self, action: #selector(reloadData), forControlEvents: .ValueChanged)
        reloadData()
    }
   
    func reloadData() {
        
        guard let _ = dataManager.remoteDataManager.user else {
            refreshControl.endRefreshing()
            collectionView?.reloadData()
            return
        }
        dataManager.userDecksWithFlashcardsCount {
            switch $0 {
            case .Success(let obj):
                self.decksArray = self.currentSortingOption.sort(obj)
            case .Error(let err):
                debugPrint(err)
                SVProgressHUD.showErrorWithStatus("Błąd pobierania danych")
            }
            self.refreshControl.endRefreshing()
            self.collectionView?.reloadData()
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        searchBar.sizeToFit()
        self.collectionView?.addSubview(refreshControl)
        if let drawer = UIApplication.sharedRootViewController as? SBDrawerController {
            drawer.addObserver(self, forKeyPath: "openSide", options: [.New, .Old], context: nil)
        }
        NSNotificationCenter.defaultCenter()
            .addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        if initialLayout {
            adjustCollectionLayout(forSize: view.bounds.size)
            initialOffset(false)
        }
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        searchController.view.removeFromSuperview()
        if let drawer = UIApplication.sharedRootViewController as? SBDrawerController {
            drawer.removeObserver(self, forKeyPath: "openSide")
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
        initialLayout = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchController.searchBar.sizeToFit()
        if initialLayout {
            initialOffset(false)
            initialLayout = !initialLayout
            
        }
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        adjustCollectionLayout(forSize: size)
        
    }
    func orientationChanged(notification: NSNotification) {
        
        if traitCollection.horizontalSizeClass != .Compact {
            initialLayout = true
            
        }
    }
   
    func initialOffset(animated: Bool) {
        collectionView?.setContentOffset(CGPoint(x: 0, y: topItemOffset + searchBarHeight), animated: animated)
    }
    
    func adjustCollectionLayout(forSize size: CGSize) {
        let layout = collectionView?.collectionViewLayout
        if let flow = layout as? UICollectionViewFlowLayout {
            let spacing = Utils.DeckViewLayout.DecksSpacing
            equalSizeAndSpacing(forScreenSize: size, cellSquareSide: Utils.DeckViewLayout.CellSquareSize, spacing: spacing, collectionFlowLayout: flow)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "openSide", let newSide = change?["new"] as? Int, oldSide = change?["old"] as? Int where newSide != oldSide {
            initialOffset(true)
        }
    }
    
    class func numberOfCellsInRow(screenWidth: CGFloat, cellSize: CGFloat) -> CGFloat {
        return floor(screenWidth / cellSize)
    }
    
    // this function calculate size of decks, by given spacing and size of cells
    private func equalSizeAndSpacing(forScreenSize screenSize: CGSize, cellSquareSide cellSize: CGFloat, spacing: CGFloat,
                                                        collectionFlowLayout flow: UICollectionViewFlowLayout){
            
        let crNumber = DecksViewController.numberOfCellsInRow(screenSize.width, cellSize: cellSize)
        
        let deckWidth = screenSize.width / crNumber - (spacing + spacing/crNumber)
        
        flow.sectionInset = UIEdgeInsets(top: 8, left: spacing, bottom: spacing, right: spacing)
        // spacing between decks
        flow.minimumInteritemSpacing = spacing
        // spacing between rows
        flow.minimumLineSpacing = spacing
        // size for every deck
        flow.itemSize = CGSize(width: deckWidth, height: deckWidth)
    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {

        return 1
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        return decksSource.isEmpty ? CGSize(width: collectionView.frame.width, height: view.frame.height + topItemOffset - 85) : CGSize.zero
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 85)
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String,
                                 atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionFooter:
            guard let emptyView = collectionView
                .dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "EmptyView", forIndexPath: indexPath) as? EmptyCollectionReusableView else {
                fatalError("Incorrect supplementary view type")
            }
            emptyView.messageLabel.text = searchController.active
                ? "Nie znaleziono talii o podanej nazwie" : "Brak talii, przesuń w górę aby wyszukać"
            return emptyView
        case UICollectionElementKindSectionHeader:
            guard let filterView = collectionView
                .dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "FilterView", forIndexPath: indexPath) as?
                CollectionReusableFilterView else {
                    fatalError("Incorrect supplementary view type")
            }
            filterView.filterButton.setTitle(currentSortingOption.description, forState: .Normal)
            filterView.filterAction = { [weak self] _, completion in
                let alert = UIAlertController(title: "Typ filtrowania", message: "", preferredStyle: .ActionSheet)
                let availableFilters: [DecksSortingOption] = [.CreateDate, .FlashcardsCount(ascending: true), .FlashcardsCount(ascending: false), .Name]
                availableFilters.forEach { option in
                    alert.addAction(UIAlertAction(title: option.description, style: .Default) { _ in
                        self?.changeSortingOption(option)
                        completion(option.description)
                    })

                }
                alert.addAction(UIAlertAction(title: "Anuluj", style: .Cancel, handler: nil))
                self?.presentViewController(alert, animated: true, completion: nil)
            }
            return filterView
            
        default:
            fatalError("Unexpected collection element")
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return decksSource.count
    }
    
    // Populate cells with decks data. Change cells style
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let view = collectionView.dequeueReusableCellWithReuseIdentifier(Utils.UIIds.DecksViewCellID, forIndexPath: indexPath)
        if let cell = view as? DecksViewCell{
            cell.layoutIfNeeded()
            cell.contentView.backgroundColor = UIColor.sb_Graphite()
            
            let deckName = decksSource[indexPath.row].0.name
            let deckFlashcardsCount = decksSource[indexPath.row].1
            
            cell.deckNameLabel.text = deckName ?? Utils.DeckViewLayout.DeckWithoutTitle
            cell.deckNameLabel.textColor = UIColor.whiteColor()
            cell.deckNameLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
            cell.deckNameLabel.preferredMaxLayoutWidth = cell.bounds.size.width
            if let nameFont = UIFont.sbFont(size: sbFontSizeLarge, bold: false) {
                cell.deckNameLabel.adjustFontSizeToHeight(nameFont, max: sbFontSizeLarge, min: sbFontSizeSmall)
            }
            cell.deckFlashcardsCountLabel.text = String(deckFlashcardsCount)
            cell.deckFlashcardsCountLabel.textColor = UIColor.whiteColor()
            if let countFont = UIFont.sbFont(size: sbFontSizeSmall, bold: false){
                cell.deckFlashcardsCountLabel.font = countFont
            }
            return cell
        }
        return view
    }
    
    // When cell tapped, change to test
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        SVProgressHUD.show()
        let deck = decksSource[indexPath.row].0
        searchBar.resignFirstResponder()
        let resetSearchUI = {
            self.searchController.active = false
        }
        
        dataManager.flashcards(deck.serverID) {
            switch $0 {
            case .Success(let flashcards):
                guard !flashcards.isEmpty else {
                    SVProgressHUD.showInfoWithStatus("Talia nie ma fiszek.")
                    return
                }
                
                let amountFlashcardsNotHidden = flashcards.reduce(0) { ret, flashcard in flashcard.hidden ? ret : ret + 1}
                
                guard amountFlashcardsNotHidden != 0 else {
                    SVProgressHUD.showInfoWithStatus("Talia ma ukryte wszystkie fiszki.")
                    return
                }
                SVProgressHUD.dismiss()
                let alert = UIAlertController(title: "Test czy nauka?", message: "Wybierz tryb, który chcesz uruchomić", preferredStyle: .Alert)
                
                let testButton = UIAlertAction(title: "Test", style: .Default){ (alert: UIAlertAction!) -> Void in
                    let alertAmount = UIAlertController(title: "Jaka ilość fiszek?", message: "Wybierz ilość fiszek w teście", preferredStyle: .Alert)
                    
                    let amounts = [ 1, 5, 10, 15, 20 ]
                    
                    for amount in amounts {
                        if amount < amountFlashcardsNotHidden {
                            alertAmount.addAction(UIAlertAction(title: String(amount), style: .Default) { act in
                                resetSearchUI()
                                self.performSegueWithIdentifier("StartTest",
                                    sender: Test(flashcards: flashcards, testType: .Test(UInt32(amount)), deck: deck))
                                })
                        } else {
                            break
                        }
                    }
                    alertAmount.addAction(UIAlertAction(title: "Wszystkie (" + String(amountFlashcardsNotHidden) + ")", style: .Default) { act in
                        resetSearchUI()
                        self.performSegueWithIdentifier("StartTest",
                            sender: Test(flashcards: flashcards, testType: .Test(UInt32(amountFlashcardsNotHidden)), deck: deck))
                        })
                    alertAmount.addAction(UIAlertAction(title: "Anuluj", style: UIAlertActionStyle.Cancel, handler: nil))
                    
                    self.presentViewController(alertAmount, animated: true, completion:nil)
                }
                let studyButton = UIAlertAction(title: "Nauka", style: .Default) { (alert: UIAlertAction!) -> Void in
                    resetSearchUI()
                    self.performSegueWithIdentifier("StartTest", sender: Test(flashcards: flashcards, testType: .Learn, deck: deck))
                }
                
                alert.addAction(testButton)
                alert.addAction(studyButton)
                alert.addAction(UIAlertAction(title: "Anuluj", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alert, animated: true, completion:nil)
                
            case .Error(_):
                SVProgressHUD.showErrorWithStatus("Nie udało się pobrać danych.")
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "StartTest", let testViewController = segue.destinationViewController as? TestViewController, testLogic = sender as? Test {
            testViewController.testLogicSource = testLogic
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @IBAction func sortButtonPress(sender: AnyObject) {
        
        let alert = UIAlertController(title: "Typ filtrowania", message: "Aktualnie:\n\(currentSortingOption.description)", preferredStyle: .ActionSheet)
        let availableFilters: [DecksSortingOption] = [.CreateDate, .FlashcardsCount(ascending: true), .FlashcardsCount(ascending: false), .Name]
        availableFilters.forEach { option in
            alert.addAction(UIAlertAction(title: option.description, style: .Default) { _ in
                self.changeSortingOption(option)
                })
            
        }
        alert.addAction(UIAlertAction(title: "Anuluj", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    
    func changeSortingOption(option: DecksSortingOption) {
        currentSortingOption = option
        decksArray = currentSortingOption.sort(decksArray)
        searchDecks = currentSortingOption.sort(searchDecks)
        collectionView?.reloadData()
    }
    
}
