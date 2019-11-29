//
//  QRCodeViewController.swift
//  KoucloiPhone
//
//  Created by kouclo on 16/4/28.
//  Copyright © 2016年 李伟. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation

class QRCodeViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate {

    ///扫描容器的高度
    @IBOutlet weak var scanViewHeight: NSLayoutConstraint!
    ///扫描线的顶部约束
    @IBOutlet weak var qrcodeLineTop: NSLayoutConstraint!
    ///扫描线的高度
    let scanLineH:CGFloat = 5
    ///动画的timer
    var timer:Timer?
    var runloop:RunLoop?
    
    ///相册图片
    var photoLibraryImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scheduledTime = NSDate(timeIntervalSinceNow: 0)
        self.timer = Timer(fireAt: scheduledTime as Date, interval: 3.0, target: self, selector: #selector(QRCodeViewController.startAnimation), userInfo: nil, repeats: true)
        runloop = RunLoop.current
        runloop!.add(self.timer!, forMode: RunLoop.Mode.common)
        // 2.开始扫描
        startScan()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        //停止扫描
        session.stopRunning()
    }
    
    //MARK:返回
    @IBAction func backBtnclick(sender: UIButton) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    //MARK:开灯
    @IBAction func QRCodeLightBtnClick(sender: UIButton) {
        
        let isLightOpened = self.isLightOpened()
        
        //可以用来调整开灯关灯的按钮状态
//        if isLightOpened{//开灯
//        
//        }else{//关灯
//        
//        }
        
        self.openLight(open: !isLightOpened)
    }
    
    //MARK:图片
    @IBAction func QRCodePhotosBtnClick(sender: UIButton) {
     
        self.openPhotoLibrary()
    }
    
    /**
     执行动画
     */
    @objc func startAnimation()
    {
        // 让约束从顶部开始
        self.qrcodeLineTop.constant = 0
        self.view.layoutIfNeeded()
        
        //
        weak var weakSelf = self
        UIView.animate(withDuration: 3.0, animations: { () -> Void in
            // 1.修改约束
            self.qrcodeLineTop.constant = weakSelf!.scanViewHeight.constant - weakSelf!.scanLineH
            // 设置动画指定的次数
//            UIView.setAnimationRepeatCount(MAXFLOAT)
            // 2.强制更新界面
            weakSelf!.view.layoutIfNeeded()
        })
    }

    
    // MARK: - 懒加载
    // 会话
    lazy var session : AVCaptureSession = AVCaptureSession()
    
    // 拿到输入设备
    private lazy var deviceInput: AVCaptureDeviceInput? = {
        // 获取摄像头
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            // 创建输入对象
            if let device = device {
                let input = try AVCaptureDeviceInput(device: device)
                return input
            } else {
                return nil
            }
        }catch
        {
            return nil
        }
    }()
    
    
    // 拿到输出对象
    private lazy var output: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    
    // 创建预览图层
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.frame = UIScreen.main.bounds
        return layer
    }()
    
    
    // 创建用于绘制边线的图层
    private lazy var drawLayer: CALayer = {
        let layer = CALayer()
        layer.frame = UIScreen.main.bounds
        return layer
    }()
    
}



//MARK:--打开闪光灯的方法
extension QRCodeViewController{
    ///判断闪光灯是否打开
    private func isLightOpened()-> Bool {
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if !(device?.hasTorch ?? false) {
            return false
        } else {
            if device?.torchMode == AVCaptureDevice.TorchMode.on {//闪光灯已经打开
                return true
            }else{
                return false
            }
        }
    }
    
    ///打开闪光灯的方法
    private func openLight(open:Bool){
    
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        if !(device?.hasTorch ?? false) {
            let alert = UIAlertView()
            alert.title = "提示"
            alert.message = "闪光灯故障"
            alert.addButton(withTitle: "确定")
            alert.show()
        } else {
            if open { //打开
                if  device?.torchMode != AVCaptureDevice.TorchMode.on || device?.flashMode != AVCaptureDevice.FlashMode.on {
    
                    do{
                        try device?.lockForConfiguration()
                        device?.torchMode = AVCaptureDevice.TorchMode.on
                        device?.flashMode = AVCaptureDevice.FlashMode.on
                        device?.unlockForConfiguration()
                    }catch
                    {
                        print(error)
                        
                    }
                }
            }else{//关闭闪光灯
        
                if  device?.torchMode != AVCaptureDevice.TorchMode.off || device?.flashMode != AVCaptureDevice.FlashMode.off {
                    
                    do{
                        try device?.lockForConfiguration()
                        device?.torchMode = AVCaptureDevice.TorchMode.off
                        device?.flashMode = AVCaptureDevice.FlashMode.off
                        device?.unlockForConfiguration()
                        
                    }catch
                    {
                        print(error)
                        
                    }
                }
        
            }
            
        }
        
    }

    ///

}



//MARK:扫描二维码的方法和代理
extension QRCodeViewController: UIAlertViewDelegate {

    /**
     扫描二维码
     */
    private func startScan(){
        guard let deviceInput = deviceInput else {
            return
        }
        // 1.判断是否能够将输入添加到会话中
        if !session.canAddInput(deviceInput)
        {
            return
        }
        // 2.判断是否能够将输出添加到会话中
        if !session.canAddOutput(output)
        {
            return
        }
        // 3.将输入和输出都添加到会话中
        session.addInput(deviceInput)
        session.addOutput(output)
        // 4.设置输出能够解析的数据类型
        output.metadataObjectTypes =  output.availableMetadataObjectTypes
        print(output.availableMetadataObjectTypes)
        // 5.设置输出对象的代理, 只要解析成功就会通知代理
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
//        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        // 添加预览图层
        view.layer.insertSublayer(previewLayer, at: 0)
        // 添加绘制图层到预览图层上
        previewLayer.addSublayer(drawLayer)
        // 6.告诉session开始扫描
        session.startRunning()
    }
    
    // 只要解析到数据就会调用
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // 1.获取扫描到的数据
            // 注意: 要使用stringValue
        let result = (metadataObjects.last as? AVMetadataMachineReadableCodeObject)?.stringValue
        print(result ?? "")
        if result != nil {
            let alert = UIAlertView()

            session.stopRunning()
        }
    }
    
    //MARK: UIAlertViewDelegate 代理方法
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        session.startRunning()
    }
}

//MARK:--访问相册和从相册解析二维码的方法
extension QRCodeViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{

    ///打开相册的方法
    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            let type = (info as NSDictionary).object(forKey: UIImagePickerController.InfoKey.mediaType) as! String
            session.stopRunning()
            if type == "public.image"
            {
                let image = (info as NSDictionary).object(forKey: UIImagePickerController.InfoKey.originalImage) as! UIImage
                self.photoLibraryImage = image
                //识别二维码的方法
                let result = image.decodeQRImage(with: image)
                //跳转的方法
                if result != nil{
                
    //                UIAlertView(title: "提示", message: "扫描结果为:\(result!)", delegate: self, cancelButtonTitle: "确定").show()
                    
                }else{
                
    //                UIAlertView(title: "提示", message: "不能识别的类型", delegate: self, cancelButtonTitle: "确定").show()
                }
            
            }
            
            self.dismiss(animated: true) { () -> Void in}
    }
    private func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let type = (info as NSDictionary).object(forKey: UIImagePickerController.InfoKey.mediaType) as! String
        session.stopRunning()
        if type == "public.image"
        {
            let image = (info as NSDictionary).object(forKey: UIImagePickerController.InfoKey.originalImage) as! UIImage
            self.photoLibraryImage = image
            //识别二维码的方法
            let result = image.decodeQRImage(with: image)
            //跳转的方法
            if result != nil{
            
//                UIAlertView(title: "提示", message: "扫描结果为:\(result!)", delegate: self, cancelButtonTitle: "确定").show()
                
            }else{
            
//                UIAlertView(title: "提示", message: "不能识别的类型", delegate: self, cancelButtonTitle: "确定").show()
            }
        
        }
        
        self.dismiss(animated: true) { () -> Void in}
    }
    
}


