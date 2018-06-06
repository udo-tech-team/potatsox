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
    
    var isButtonSelected = false

    init(allowNone: Bool = false, chooseCallback: ((Proxy?) -> Void)? = nil) {
        self.chooseCallback = chooseCallback
        self.allowNone = allowNone
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

    func reloadData() {
        proxies = DBUtils.allNotDeleted(Proxy.self, sorted: "createAt").map({ $0 })
//        if allowNone {
//            proxies.insert(nil, at: 0)
//        }
        form.delegate = nil
        form.removeAll()
        let section = Section("高速线路")
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
        for proxy in proxies {
            section
                <<< ProxyRow () {
                    $0.value = proxy
                }.cellSetup({ (cell, row) -> () in
                    cell.selectionStyle = .none
                    //创建一个按钮
                    let button: UIButton = UIButton(type: .infoLight)
                    //设置按钮位置和大小
                    button.frame = CGRect(x: cell.frame.origin.x + UIScreen.main.bounds.width - cell.frame.size.height, y: cell.frame.origin.y, width: cell.frame.size.height, height: cell.frame.size.height)
                    cell.addSubview(button)
                    button.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                }).onCellSelection({ [unowned self] (cell, row) in
                    cell.setSelected(false, animated: true)
                    let proxy = row.value
                    if self.isButtonSelected == false {
                    if let cb = self.chooseCallback {
                        cb(proxy)
                        self.close()
                    }
                    } else if self.isButtonSelected == true {
                            if proxy?.type != .none {
                                self.showProxyConfiguration(proxy)
                        }
                        self.isButtonSelected = false
                    }
                })
        }
        form +++ section
            <<< ButtonRow(){
                $0.title = "购买线路"
        }
        
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
        }
        form.delegate = self
        tableView?.reloadData()
    }

    func showProxyConfiguration(_ proxy: Proxy?) {
        let vc = ProxyConfigurationViewController(upstreamProxy: proxy)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc func buttonAction() {
        print("点击成功")
        isButtonSelected = true
        //let vc = ProxyConfigurationViewController()
        //navigationController?.pushViewController(vc, animated: true)
    }
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
                try DBUtils.softDelete(item.uuid, type: Proxy.self)
                proxies.remove(at: indexPath.row)
                form[indexPath].hidden = true
                form[indexPath].evaluateHidden()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView?.tableFooterView = UIView()
        tableView?.tableHeaderView = UIView()
    }

}
