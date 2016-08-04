//
//  MoviesViewController.swift
//  Flicks
//
//  Created by phil_nachum on 8/1/16.
//  Copyright © 2016 phil_nachum. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

let LIST_VIEW = 0
let GRID_VIEW = 1

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var viewTypeControl: UISegmentedControl!

    var movies: [NSDictionary]!
    var endpoint: String!
    var searchBar: UISearchBar!
    var searchText: String!

    var filtered: [NSDictionary] {
        if let movies = movies {
            return movies.filter { (movie) -> Bool in
                let title = (movie["title"] as? String)?.lowercaseString ?? ""
                let search = searchText.lowercaseString
                return (search.characters.count == 0) || title.rangeOfString(search) != nil
            }
        } else {
            return []
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        searchBar = UISearchBar()
        navigationItem.titleView = searchBar
        searchBar.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(fetchData(_:)), forControlEvents: UIControlEvents.ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)

        fetchData(refreshControl)

        displayMovies(viewTypeControl.selectedSegmentIndex)

        // Do any additional setup after loading the view.
    }
    
    // Search bar methods

    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        updateMoviesData(movies, searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.endEditing(true)
        searchBar.text = ""
        updateMoviesData(movies, searchText: "")
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    // Collection view methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filtered.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieGridCell", forIndexPath: indexPath) as! MovieGridCell
        let movie = filtered[indexPath.row]
        
        if let posterPath = (movie["poster_path"] as? String) {
            setPosterImage(posterPath, posterView: cell.posterImageView)
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = collectionView.frame.width / 3
        // Roughly the ratio of a movie poster
        let height = width / 0.65
        return CGSize(width: width, height: height)
    }
    
    // Table view methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = filtered[indexPath.row]
        if let posterPath = movie["poster_path"] as? String {
            setPosterImage(posterPath, posterView: cell.posterView)
        }
        
        cell.titleLabel.text = movie["title"] as? String
        cell.overviewLabel.text = movie["overview"] as? String
        return cell
    }

    private func updateMoviesData(movies: [NSDictionary], searchText: String) {
        self.movies = movies
        self.searchText = searchText
        tableView.reloadData()
        collectionView.reloadData()
    }

    private func displayMovies(viewType: Int) {
        if (viewType == LIST_VIEW) {
            tableView.hidden = false
            collectionView.hidden = true
        } else if (viewType == GRID_VIEW) {
            tableView.hidden = true
            collectionView.hidden = false
        }
    }

    @objc private func fetchData(refreshControl: UIRefreshControl) {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!,
            cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData,
            timeoutInterval: 10)

        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )

        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
             completionHandler: { (dataOrNil, response, error) in
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                refreshControl.endRefreshing()
                if error != nil {
                    self.networkErrorView.hidden = false
                }
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                        self.updateMoviesData(responseDictionary["results"] as! [NSDictionary], searchText: self.searchBar.text ?? "")
                        self.networkErrorView.hidden = true
                    }
                }
        })
        task.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setPosterImage(posterPath: String, posterView: UIImageView) {
        
        let baseImageUrl = "http://image.tmdb.org/t/p/w500"
        let imageRequest = NSURLRequest(URL: NSURL(string: baseImageUrl + posterPath)!)
        
        posterView.setImageWithURLRequest(
            imageRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    posterView.alpha = 0.0
                    posterView.image = image
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                        posterView.alpha = 1.0
                    })
                } else {
                    posterView.image = image
                }
            },
            failure: { (imageRequest, imageResponse, error) -> Void in
                self.networkErrorView.hidden = false
        })
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let detailViewController = segue.destinationViewController as! DetailViewController
        let viewType = viewTypeControl.selectedSegmentIndex
        let movie: NSDictionary
        if viewType == LIST_VIEW {
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            movie = filtered[indexPath!.row]
        } else {
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView.indexPathForCell(cell)
            movie = filtered[indexPath!.row]
        }
        detailViewController.movie = movie
    }
    @IBAction func viewTypeChanged(sender: AnyObject) {
        displayMovies(viewTypeControl.selectedSegmentIndex)
    }
}
