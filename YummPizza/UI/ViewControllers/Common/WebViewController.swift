//
//  WebViewController.swift
//  YummPizza
//
//  Created by Blaze Mac on 5/12/17.
//  Copyright © 2017 Code Inspiration. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate
{
   var url : URL?
   {
      didSet
      {
         if let webview = webView
         {
            if let webURL = url
            {
               let request = URLRequest(url: webURL)
               webview.load(request)
            }
            else
            {
               webview.loadHTMLString("", baseURL: nil)
            }
         }
      }
   }
   
   var showSpinnerWhenLoading : Bool = true
   
   private(set) var webView : WKWebView!
   
   
   override func viewDidLoad()
   {
      super.viewDidLoad()
      webView = WKWebView(frame: view.bounds)
      webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      view.addSubview(webView)
      webView.navigationDelegate = self
      
      if let webURL = url
      {
         let request = URLRequest(url: webURL)
         webView.load(request)
         
         if showSpinnerWhenLoading {
            showAppSpinner(addedTo: webView, animated: false)
         }
      }
   }
   
   override func viewWillAppear(_ animated: Bool)
   {
      super.viewWillAppear(animated)
      if let navigationBar = navigationController?.navigationBar
      {
         navigationBar.isTranslucent = false
         navigationBar.shadowImage = nil
         navigationBar.setBackgroundImage(nil, for: UIBarMetrics.default)
      }
   }
   
   //MARK: - WKNavigation
   
   public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)
   {
      if navigationAction.navigationType == .linkActivated, let targetUrl = navigationAction.request.url
      {
         decisionHandler(.cancel)
         Application.openURL(targetUrl)
      }
      else
      {
         decisionHandler(.allow)
      }
   }
   
   public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
   {
      if showSpinnerWhenLoading {
         hideAppSpinner(for: webView, animated: true)
      }
   }
}
