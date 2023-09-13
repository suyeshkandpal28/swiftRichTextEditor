//
//  ViewController.swift
//  RichTextEditor
//
//  Created by Suyesh Kandpal on 13/09/23.
//

import UIKit
import WebKit

protocol RichTextEditiorDelegate: AnyObject {
func getRichText(text : String?)
}

class ViewController: UIViewController {
    
    var delegate : RichTextEditiorDelegate?
    @IBOutlet weak var webView: WKWebView!
    var richTextString : String = ""
    var htmlCallbackState : Bool = false
    var editedText : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self
        webView.configuration.userContentController.add(self, name: "content")
        setupWebView()
        loadQuillEditor()
    }
    
    func setupWebView() {
        let viewportScriptString = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); meta.setAttribute('initial-scale', '1.0'); meta.setAttribute('maximum-scale', '1.0'); meta.setAttribute('minimum-scale', '1.0'); meta.setAttribute('user-scalable', 'no'); document.getElementsByTagName('head')[0].appendChild(meta);"

        let disableSelectionScriptString = "document.documentElement.style.webkitUserSelect='none';"

        let disableCalloutScriptString = "document.documentElement.style.webkitTouchCallout='none';"

        
        let viewportScript = WKUserScript(source: viewportScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableSelectionScript = WKUserScript(source: disableSelectionScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableCalloutScript = WKUserScript(source: disableCalloutScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        webView.configuration.userContentController.addUserScript(viewportScript)
        webView.configuration.userContentController.addUserScript(disableSelectionScript)
        webView.configuration.userContentController.addUserScript(disableCalloutScript)
    }
    
    func loadHtmlData() {
        if !editedText.isEmpty{
            let javascriptFunction = "setQuillContent('\(editedText)');"
            webView.evaluateJavaScript(javascriptFunction, completionHandler: nil)
        }
    }
    
    func loadQuillEditor() {
        if let htmlFilePath = Bundle.main.path(forResource: "quill", ofType: "html") {
            let htmlFileURL = URL(fileURLWithPath: htmlFilePath)
            webView.loadFileURL(htmlFileURL, allowingReadAccessTo: htmlFileURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: {
                self.loadHtmlData()
            })
        }
    }
    
    func setQuillContent(htmlContent: String) {
        let javascriptFunction = "setQuillContent('\(htmlContent)');"
        webView.evaluateJavaScript(javascriptFunction, completionHandler: { (_, error) in
            if let error = error {
                print("Error setting Quill content: \(error.localizedDescription)")
            } else {
                print("Quill content set successfully.")
            }
        })
    }
}
//webview deleagate
extension ViewController : WKNavigationDelegate, WKScriptMessageHandler {
    // Handle content messages from JavaScript
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "content", let content = message.body as? String {
            // Handle the received content from Quill editor
            richTextString = content
            self.htmlCallbackState = true
            print("Received content from Quill editor: \(content)")
        }
    }
}
//MARK:UIACTION
extension ViewController {
    @IBAction func backButtonPressed() {
        htmlCallbackState = false
        webView.evaluateJavaScript("sendContentToiOS()") { (_, error) in
            if let error = error {
                print("Error sending content to iOS: \(error.localizedDescription)")
            }
            if self.htmlCallbackState {
                self.htmlCallbackState = false
                self.delegate?.getRichText(text: self.richTextString)
                self.richTextString = ""
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}


