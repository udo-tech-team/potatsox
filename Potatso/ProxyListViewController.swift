//
//  ProxyListViewController.swift
//  Potatso
//
//  Created by LEI on 5/31/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoModel
import Cartography
import Eureka

private let rowHeight: CGFloat = 107
private let kProxyCellIdentifier = "proxy"

class ProxyListViewController: FormViewController {

    var proxies: [Proxy?] = []
    let allowNone: Bool
    let chooseCallback: ((Proxy?) -> Void)?
    
    var free_proxy_bob: Proxy
    var free_proxy_alice: Proxy
    
    var isButtonSelected = false

    init(allowNone: Bool = false, chooseCallback: ((Proxy?) -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.allowNone = allowNone
        self.free_proxy_bob = Proxy()
        self.free_proxy_alice = Proxy()
        self.free_proxy_bob.name = "abc"
        self.free_proxy_alice.name = "def"
        print("bob:\(self.free_proxy_bob.name), alice:\(self.free_proxy_alice.name)")
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.title = "Proxy".localized()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
        reloadData()
    }

    @objc func add() {
        let vc = ProxyConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func setFreeLine(proxy: Proxy? = nil) {
        if let proxy = proxy {
            proxy.name = "Free"
            proxy.host = "a.xhide.live"
            proxy.password = "ded36zcm"
            proxy.port = 8088
            proxy.type = ProxyType.ShadowsocksR
            proxy.authscheme = "aes-256-cfb"
            proxy.ssrProtocol = "origin"
            proxy.ssrObfs = "http_simple"
            proxy.ssrObfsParam = "bing.com"
        } else {
            // TODO with nil
        }
    }
    
    @objc func insertFreeLine() {
        self.setFreeLine(proxy: self.free_proxy_bob)
        self.setFreeLine(proxy: self.free_proxy_alice)
        
        self.free_proxy_alice.password = "ded36zcm"
        self.free_proxy_alice.host = "a.xhide.live"
        self.free_proxy_alice.name = "Free line".localized() + " 00-09am"
        
        self.free_proxy_bob.password = "rdwqc7es"
        self.free_proxy_bob.host = "b.xhide.live"
        self.free_proxy_bob.name = "Free line".localized() + " 09-17pm"
        
        do {
            print("try insert free lines")
            var bob_exist = false
            var alice_exist = false
            let tmp_proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
            for pxy in tmp_proxies {
                print(pxy.name)
                if pxy.name == self.free_proxy_bob.name {
                    print("bob exists!")
                    bob_exist = true
                }
                if pxy.name == self.free_proxy_alice.name {
                    print("alice exists")
                    alice_exist = true
                }
            }
            if !alice_exist {
                print("alice not exist, try add one.")
                try DBUtils.add(self.free_proxy_alice)
            }
            if !bob_exist {
                print("bob not exist, try add one.")
                try DBUtils.add(self.free_proxy_bob)
            }
        } catch {
            self.showTextHUD("Fail to add free line".localized(), dismissAfterDelay: 1.5)
        }
    }

    func reloadData() {
        // self.insertFreeLine()
        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
//        if allowNone {
//            proxies.insert(nil, at: 0)
//        }
        form.delegate = nil
        form.removeAll()
        let section = Section("Lines")
        
            /*
            <<< LabelRow() {
                //https://blog.xmartlabs.com/2016/09/06/Eureka-custom-row-tutorial/
                $0.title = "需要自定义 ROW 的 cell"
                }.cellSetup({ (cell, row) -> () in
                    cell.imageView?.image = #imageLiteral(resourceName: "Proxy")
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({ [unowned self](cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    let userVC = UserViewVontroller()
                    self.navigationController?.pushViewController(userVC, animated: true)
                })
                */
        var need_desc = false
        for proxy in proxies {
            need_desc = true
            section
                <<< ProxyRow () {
                    $0.value = proxy
                    print($0.value)
                    print("proxy in use:" + String(proxy!.inUse))
                    let deleteAction = SwipeAction(style: .destructive, title: "Del") { (action, row, completionHandler) in
                        print("Delete")
                        let indexPath = row.indexPath!
                        print(indexPath)
                        //let item = (self.form[indexPath] as? ProxyRow)?.value
                        if proxy!.inUse {
                            let warn_info = "Fail to delete item".localized() + ":" + "Config in use".localized()
                            self.showTextHUD(warn_info, dismissAfterDelay: 1.5)
                            return
                        }
                        
                        do {
                            print("in row delete proxy, uuid:\(String(describing: proxy?.uuid)), type:\(Proxy.self)")
                            try DBUtils.hardDelete((proxy?.uuid)!, type: Proxy.self)
                            guard indexPath.row >= 1 else {
                                throw "Proxy row index error".localized() + ":" + String(indexPath.row)
                            }
                            self.proxies.remove(at: indexPath.row-1)
                            self.form[indexPath].hidden = true
                            self.form[indexPath].evaluateHidden()
                        }catch {
                            self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
                        }
                        
                        completionHandler?(true)
                    }
                    $0.trailingSwipe.actions = [deleteAction]
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .none
                    ////备用,勿删
//                    //创建一个按钮
//                    let button: UIButton = UIButton(type: .infoLight)
//                    //设置按钮位置和大小
//                    button.frame = CGRect(x: cell.frame.origin.x + UIScreen.main.bounds.width - cell.frame.size.height, y: cell.frame.origin.y, width: cell.frame.size.height, height: cell.frame.size.height)
//                    cell.addSubview(button)
                    //button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                    
                    cell.accessoryType = .detailDisclosureButton
                    
                }).onCellSelection({ [unowned self] (cell, row) in
                    cell.setSelected(false, animated: true)
                    let proxy = row.value
                    if self.isButtonSelected == false {
                    if let cb = self.chooseCallback {
                        cb(proxy)
                        // update proxies inuse status
                        do {
                            try DBUtils.updateProxyInuse(proxy: proxy!)
                        } catch {
                            let warn_info = "Fail to switch proxy".localized() + ":" + "Realm transaction error".localized()
                            self.showTextHUD(warn_info, dismissAfterDelay: 1.5)
                            return
                        }
                        self.close()
                    }
                    } else if self.isButtonSelected == true {
                            if proxy?.type != .none {
                                print("show proxy:\(String(describing: proxy))")
                                self.showProxyConfiguration(proxy)
                        }
                        self.isButtonSelected = false
                    }
                })
        }
        
        if need_desc {
            section <<< LabelRow { row in
                row.title = "Tell user how to delete/switch proxy"
                row.cell.textLabel?.numberOfLines = 1
                //row.cell.height = ({return 10})
                row.cell.textLabel?.adjustsFontSizeToFitWidth = true
                row.cell.textLabel?.textColor = UIColor.blue
                row.cell.textLabel?.font = UIFont(name: "Arial", size: 14)
            }
        }
        
        form +++ section
        /*
            <<< ButtonRow(){
                $0.title = "购买线路"
        }
        */
        
        
        /* TODO
        form +++ Section("免费线路")
            <<< LabelRow() {
                $0.title = "需要自定义 ROW 的 cell"
                }.cellSetup({ (cell, row) -> () in
                    cell.imageView?.image = #imageLiteral(resourceName: "Proxy")
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({ [unowned self](cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    let userVC = UserViewVontroller()
                    self.navigationController?.pushViewController(userVC, animated: true)
                })
            <<< ButtonRow(){
                $0.title = "积分兑换"
 
            }*/
        form.delegate = self
        tableView?.reloadData()
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        print(indexPath.row)
        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
        var idx = 0
        if indexPath.row >= 1 {
            idx = indexPath.row - 1
        }
        print("idx=\(idx), indexPath.row=\(indexPath.row)")
        let proxy = proxies[indexPath.row]
        if proxy?.type != .none {
            self.showProxyConfiguration(proxy)
        }        
    }

    func showProxyConfiguration(_ proxy: Proxy?) {
        print("try to edit proxy config, proxy:\(String(describing: proxy))")
        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
        navigationController?.pushViewController(vc, animated: true)
    }
//备用,勿删
//    @objc func buttonAction(_ sender: AnyObject) {
//
//        let btn = sender as! UIButton
//        let cell = superUITableViewCell(of: btn)!
//        //let cell = btn.superView(of: UITableViewCell.self)!
//        let indexPath = tableView.indexPath(for: cell)
//        let label = cell.viewWithTag(1) as! UILabel
//        print(label.text!)
//        print("indexPath：\(indexPath!)")
//        print("点击成功")
//        isButtonSelected = true
//        //let vc = ProxyConfigurationViewController()
//        //navigationController?.pushViewController(vc, animated: true)
//    }
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if allowNone && indexPath.row == 0 {
            return false
        }
        return true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard indexPath.row < proxies.count, let item = (form[indexPath] as? ProxyRow)?.value else {
                return
            }
            do {
                print("in table view try delete uuid\(item.uuid), proxy\(Proxy.self)")
                try DBUtils.softDelete(item.uuid, type: Proxy.self)
                proxies.remove(at: indexPath.row)
                form[indexPath].hidden = true
                form[indexPath].evaluateHidden()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }
//    //返回编辑类型，滑动删除
//    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        return UITableViewCellEditingStyle.delete
//    }
//
    //在这里修改删除按钮的文字
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Delete"
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView?.tableFooterView = UIView()
        tableView?.tableHeaderView = UIView()
    }
    //返回button所在的UITableViewCell
    func superUITableViewCell(of: UIButton) -> UITableViewCell? {
        for view in sequence(first: of.superview, next: { $0?.superview }) {
            if let cell = view as? UITableViewCell {
                return cell
            }
        }
        return nil
    }
}
extension UIResponder {
    
    func next<T: UIResponder>(_ type: T.Type) -> T? {
        return next as? T ?? next?.next(type)
    }
}
extension UITableViewCell {
    
    var tableView: UITableView? {
        return next(UITableView.self)
    }
    
    var indexPath: IndexPath? {
        return tableView?.indexPath(for: self)
    }
}
