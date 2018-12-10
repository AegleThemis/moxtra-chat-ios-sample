//
//  ViewController.swift
//  SwiftMoxie
//
//  Created by Moxtra on 2017/7/24.
//  Copyright © 2017年 moxtra. All rights reserved.
//

import UIKit

/*SDK configuration */
private let kBaseDomain = "www.grouphour.com"
private let kCLientID = "ODMyNGYyMzI"
private let kClientSecret = "OWI5OGMzMjM"
private let kUniqueID = "mc_jacob"
private let kOrgID = "PP2iXx2qi4f46aic2WD01Y7"

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,MXChatClientDelegate,MXChatListModelDelegate {
    private let kCellReuseIdentifier = "kCellReustIdentifier"
    private var tableView:UITableView!
    
    private var chatListModel:MXChatListModel {
        get {
            if _chatListModel == nil {
                _chatListModel = MXChatListModel.init()
                _chatListModel!.delegate = self
            }
            return _chatListModel!
        }
    }
    var _chatListModel:MXChatListModel?
    
    private var meetListModel:MXMeetListModel {
        if _meetListModel == nil {
            _meetListModel = MXMeetListModel.init()
        }
        return _meetListModel!
    }
    var _meetListModel:MXMeetListModel?
    
    private lazy var chatList:Array<MXChat> = {
       return Array.init()
    }()
    
    private var lastOpenChat:MXChat!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        MXChatClient.sharedInstance().delegate = self
        login()
        setupUserInterface()
    }
    
    //MARK: - UserInterface
    private func setupUserInterface() {
        tableView = UITableView.init(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        view.addSubview(tableView)
        
        let leftBarButtonItem = UIBarButtonItem.init(title: "APIs", style: .plain, target: self, action: #selector(apiButtonOnClicked))
        navigationItem.leftBarButtonItem = leftBarButtonItem

    }
    
    //MARK: - TableViewDelegate/DataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier)
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: kCellReuseIdentifier)
        }
        let chatItem = chatList[indexPath.row]
        cell?.textLabel?.text = chatItem.topic
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chatItem = chatList[indexPath.row]
        let chatViewController = MXChatViewController.init(chat: chatItem)
        chatViewController.edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
        self.lastOpenChat = chatItem;
        navigationController?.pushViewController(chatViewController, animated: true)
    }
    
    //MARK: - WidgetsAction
    @objc private func apiButtonOnClicked(sender: UIBarButtonItem) {
        weak var weakSelf = self
        
        let alert = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction.init(title: "Login", style: .default, handler: { (action) in
            weakSelf?.login()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Unlink Accout", style: .default, handler: { (action) in
            weakSelf?.unlink()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Fetch Chat List", style: .default, handler: { (action) in
            weakSelf?.fetchChatList()
        }))
        
        alert.addAction(UIAlertAction.init(title: "New Chat", style: .default, handler: { (action) in
            weakSelf?.startNewChat()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Start Meet", style: .default, handler: { (action) in
            weakSelf?.startMeet()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Join Meet", style: .default, handler: { (action) in
            weakSelf?.joinMeet()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Delete Last Open Chat", style: .default, handler: { (action) in
            weakSelf?.deleteLastOpenChat()
        }))
        
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            
        }))
        
        alert.popoverPresentationController?.barButtonItem = sender
        present(alert, animated: true, completion: nil)
    }
    
    
    //MARK: - ChatSDKActions
    private func login() {
        weak var weakSelf = self
        MXChatClient.sharedInstance().setupDomain(kBaseDomain, httpsDomain: nil, wssDomain: nil, linkConfig: nil)
        MXChatClient.sharedInstance().link(withUniqueId: kUniqueID, orgId: kOrgID, clientId: kCLientID, clientSecret: kClientSecret) { (error) in
            if (error != nil) {
                weakSelf?.alertWithError(error: error!)
            }
            else {
                weakSelf?.alertWithMessage(message: "Login Success")
            }
        }
    }
    
    private func unlink() {
        MXChatClient.sharedInstance().unlink()
        chatList.removeAll()
        tableView.reloadData()
    }
    
    private func fetchChatList() {
        if checkLogin() {
            chatList = chatListModel.chats()
            tableView.reloadData()
        }
    }
    
    private func startNewChat() {
        if checkLogin() {
            weak var weakSelf = self
            weak var blockTextFiled:UITextField?
            let addChatAlert = UIAlertController.init(title: "Chat's Topic", message: nil, preferredStyle: .alert)
            addChatAlert.addTextField { (textField) in
                blockTextFiled = textField
            }
            addChatAlert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            addChatAlert.addAction(UIAlertAction.init(title: "Done", style: .default, handler: { (action) in
                weakSelf?.chatListModel.createChat(withTopic: blockTextFiled?.text, completionHandler: { (error, chatItem) in
                    if (error != nil) {
                        weakSelf?.alertWithError(error: error!)
                    } else {
                        let chatViewController = MXChatViewController.init(chat: chatItem!)
                        chatViewController.edgesForExtendedLayout = UIRectEdge.init(rawValue: 0)
                        weakSelf?.lastOpenChat = chatItem
                        weakSelf?.navigationController?.pushViewController(chatViewController, animated: true)
                    }
                })
            }))
            present(addChatAlert, animated: true, completion: nil)
        }
    }
    
    private func startMeet() {
        if checkLogin() {
            weak var weakSelf = self
            meetListModel.startMeet(withTopic: "New Meet", completionHandler: { (error, meetSession) in
                if (error != nil) {
                    weakSelf?.alertWithError(error: error!)
                } else {
                    meetSession?.presentMeetWindow()
                }
            })
        }
    }
    
    private func joinMeet() {
        if checkLogin() {
            weak var weakSelf = self
            weak var blockTextField:UITextField?
            let joinMeetAlert = UIAlertController.init(title: "Input Meet ID", message: nil
                , preferredStyle: .alert)
            joinMeetAlert.addTextField { (textField) in
                textField.placeholder = "meet's id"
                blockTextField = textField
            }
            joinMeetAlert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil))
            joinMeetAlert.addAction(UIAlertAction.init(title: "Join", style: .default, handler: { (action) in
                weakSelf?.meetListModel.joinMeet(withMeetId: (blockTextField?.text)!, completionHandler: { (error, meetSession) in
                    if error != nil {
                        weakSelf?.alertWithError(error: error!)
                    } else {
                        meetSession?.presentMeetWindow()
                    }
                })
            }))
            present(joinMeetAlert, animated: true, completion: nil)
        }
    }
    
    private func deleteLastOpenChat() {
        if checkLogin() {
            weak var weakSelf = self
            if lastOpenChat != nil {
                chatListModel.deleteOrLeaveChat(lastOpenChat, withCompletionHandler: { (error) in
                    if error != nil {
                        weakSelf?.alertWithError(error: error!)
                    } else {
                        weakSelf?.lastOpenChat = nil
                    }
                })
            }
            else {
                alertWithMessage(message: "Could not found last open chat")
            }
        }
    }
    
    //MARK: - Helper
    private func alertWithError(error: Error) {
        let title = "Error"
        let message = String.init(format: "%@", error.localizedDescription)
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler:nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func alertWithMessage(message: String) {
        let title = "Tip"
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler:nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func checkLogin() -> Bool {
        if  MXChatClient.sharedInstance().currentUser != nil {
            return true
        } else {
            alertWithMessage(message: "Please Login first")
            return false
        }
    }
    
    
    //MARK: - MXChatClientDelegate
    func chatClientDidUnlink(_ chatClient: MXChatClient) {
        _chatListModel = nil
        _meetListModel = nil
        lastOpenChat = nil
        alertWithMessage(message: "Unlink success")
    }
    
    //MARK: - MXChatListModelDelegate
    func chatListModel(_ chatListModel: MXChatListModel, didCreateChats createdChats: [MXChat]) {
        for chatItem in createdChats {
            chatList.insert(chatItem, at: 0)
        }
        tableView.reloadData()
    }
    
    func chatListModel(_ chatListModel: MXChatListModel, didUpdate updatedChats: [MXChat]) {
        tableView.reloadData()
    }

    func chatListModel(_ chatListModel: MXChatListModel, didDelete deletedChats: [MXChat]) {
        for chatItem in deletedChats {
            chatList.remove(at: chatList.index(of: chatItem)!)
        }
        tableView.reloadData()
    }
}

