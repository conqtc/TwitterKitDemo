//
//  SearchTweetsViewController.swift
//  TwitterKitDemo
//
//  Created by Alex Truong on 5/14/17.
//  Copyright © 2017 Alex Truong. All rights reserved.
//

import UIKit
import MapKit
import TwitterKit
import SwiftyJSON

class SearchTweetsViewController: UITableViewController {
    let kSearchEndPoint = "https://api.twitter.com/1.1/search/tweets.json"
    let kTweetTableReuseIdentifier = "TweetCell"

    let apiClient = TWTRAPIClient()
    
    var tweets: [TWTRTweet] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    let kRadius = 20
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var searchText: String = "Melbourne"
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)

    func startLoadingAnimation() {
        activityIndicator.backgroundColor = UIColor.darkGray
        activityIndicator.layer.cornerRadius = 5.0
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        activityIndicator.center = tableView.center
        tableView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func stopLoadingAnimation() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsSelection = false
        tableView.register(TWTRTweetTableViewCell.self, forCellReuseIdentifier: kTweetTableReuseIdentifier)
        
        navigationItem.title = "Related Tweets"
        
        startLoadingAnimation()
        searchForTweets()
    }
    
    func searchForTweets() {
        let geocode = String(format: "%.5f,%.5f,%dkm", latitude, longitude, kRadius)
        let params = [
            "q": searchText,
            "geocode": geocode
        ]
        
        let request = apiClient.urlRequest(withMethod: "GET", url: kSearchEndPoint, parameters: params, error: nil)
        
        apiClient.sendTwitterRequest(request) { response, data, connectionError in
            DispatchQueue.main.async {
                self.stopLoadingAnimation()
            }
            
            if connectionError != nil {
                print("connection error: \(String(describing: connectionError?.localizedDescription))")
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: [])
                let jsonObject = JSON(json)
                if let jsonTweets = jsonObject["statuses"].arrayObject {
                    self.tweets = TWTRTweet.tweets(withJSONArray: jsonTweets) as! [TWTRTweet]
                }
            } catch let jsonError {
                print("json error: \(jsonError.localizedDescription)")
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kTweetTableReuseIdentifier, for: indexPath) as! TWTRTweetTableViewCell

        let tweet = tweets[indexPath.row]
        cell.configure(with: tweet)
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let tweet = tweets[indexPath.row]
        return TWTRTweetTableViewCell.height(for: tweet, style: .compact, width: self.tableView.bounds.width, showingActions: false)
    }
}
