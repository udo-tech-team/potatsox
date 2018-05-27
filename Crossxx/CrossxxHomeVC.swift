//
//  CrossxxHomeVC.swift
//  Potatso
//
//  Created by chinghoi on 2018/5/26.
//  Copyright © 2018年 TouchingApp. All rights reserved.
//

import Foundation
import PotatsoLibrary
import PotatsoModel
import Eureka
import ICDMaterialActivityIndicatorView
import Cartography

private let kFormName = "name"
private let kFormDNS = "dns"
private let kFormProxies = "proxies"
private let kFormDefaultToProxy = "defaultToProxy"

class CrossxxHomeVC: FormViewController, UINavigationControllerDelegate, HomePresenterProtocol, UITextFieldDelegate {
    
    let presenter = HomePresenter()
    
    var ruleSetSection: Section!
    
    var status: VPNStatus {
        didSet(o) {
            updateConnectButton()
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.status = .off
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        presenter.bindToVC(self)
        presenter.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fix a UI stuck bug
        navigationController?.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Post an empty message so we could attach to packet tunnel process
        tableView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 200)
        Manager.sharedManager.postMessage()
        handleRefreshUI()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add))
    }
    
    // MARK: - HomePresenter Protocol
    
    func handleRefreshUI() {
        if presenter.group.isDefault {
            status = Manager.sharedManager.vpnStatus
        }else {
            status = .off
        }
        updateForm()
    }
    @objc func add() {
        let vc = ProxyConfigurationViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    func updateForm() {
        form.delegate = nil
        form.removeAll()
        form +++ generateProxySection()
        
        form.delegate = self
        tableView?.reloadData()
    }
    
    func updateConnectButton() {
        connectButton.isEnabled = [VPNStatus.on, VPNStatus.off].contains(status)
        connectButton.setTitleColor(UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), for: UIControlState())
        switch status {
        case .connecting, .disconnecting:
            connectButton.animating = true
        default:
            connectButton.setTitle(status.hintDescription, for: .normal)
            connectButton.animating = false
        }
        connectButton.backgroundColor = status.color
    }
    
    // MARK: - Form
    
    func generateProxySection() -> Section {
        let proxySection = Section()
        if let proxy = presenter.proxy {
            proxySection <<< ProxyRow(kFormProxies) {
                $0.value = proxy
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({ [unowned self](cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.presenter.chooseProxy()
                })
        }else {
            proxySection <<< LabelRow() {
                $0.title = "选择线路"
                $0.value = "None".localized()
                }.cellSetup({ (cell, row) -> () in
                    cell.accessoryType = .disclosureIndicator
                    cell.selectionStyle = .default
                }).onCellSelection({ [unowned self](cell, row) -> () in
                    cell.setSelected(false, animated: true)
                    self.presenter.chooseProxy()
                })
        }
        return proxySection
    }
    

    
    // MARK: - Private Actions
    
    @objc func handleConnectButtonPressed() {
        if status == .on {
            status = .disconnecting
        }else {
            status = .connecting
        }
        presenter.switchVPN()
    }
    
    @objc func handleTitleButtonPressed() {
        presenter.changeGroupName()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                try defaultRealm.write {
                    presenter.group.ruleSets.remove(at: indexPath.row)
                }
                form[indexPath].hidden = true
                form[indexPath].evaluateHidden()
            }catch {
                self.showTextHUD("\("Fail to delete item".localized()): \((error as NSError).localizedDescription)", dismissAfterDelay: 1.5)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    // MARK: - TextRow
    
    override func textInputDidEndEditing<T>(_ textInput: UITextInput, cell: Cell<T>) where T : Equatable {
        guard let textField = textInput as? UITextField, let dnsString = textField.text, cell.row.tag == kFormDNS else {
            return
        }
        presenter.updateDNS(dnsString)
        textField.text = presenter.group.dns
    }
    
    // MARK: - View Setup
    //连接按钮大小位置
    fileprivate let connectButtonHeight: CGFloat = 80
    fileprivate let connectButtonWidth: CGFloat = 80
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = Color.Background
        view.addSubview(connectButton)
        setupLayout()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubview(toFront: connectButton)
        tableView?.contentInset = UIEdgeInsetsMake(0, 0, connectButtonHeight, 0)
    }
    
    func setupLayout() {
        constrain(connectButton, view) { connectButton, view in
            
            connectButton.centerX == view.centerX
            connectButton.centerY == view.centerY
            connectButton.width == connectButtonWidth
            connectButton.height == connectButtonHeight
            
        }
    }
    
    lazy var connectButton: FlatButton = {
        let v = FlatButton(frame: CGRect.zero)
        v.addTarget(self, action: #selector(HomeVC.handleConnectButtonPressed), for: .touchUpInside)
        return v
    }()
}

extension VPNStatus {
    
    var color: UIColor {
        switch self {
        case .on, .disconnecting:
            return Color.StatusOn
        case .off, .connecting:
            return Color.StatusOff
        }
    }
    
    var hintDescription: String {
        switch self {
        case .on, .disconnecting:
            return "Disconnect".localized()
        case .off, .connecting:
            return "Connect".localized()
        }
    }
}
