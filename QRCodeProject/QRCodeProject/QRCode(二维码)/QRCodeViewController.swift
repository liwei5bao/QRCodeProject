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
    var timer:NSTimer?
    var runloop:NSRunLoop?
    
    ///相册图片
    var photoLibraryImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let scheduledTime = NSDate(timeIntervalSinceNow: 0)
        self.timer = NSTimer(fireDate: scheduledTime, interval: 3.0, target: self, selector: "startAnimation", userInfo: nil, repeats: true)
        runloop = NSRunLoop.currentRunLoop()
        runloop!.addTimer(self.timer!, forMode: NSDefaultRunLoopMode)
        // 2.开始扫描
        startScan()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        session.startRunning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        //停止扫描
        session.stopRunning()
    }
    
    //MARK:返回
    @IBAction func backBtnclick(sender: UIButton) {
        
        self.navigationController?.popViewControllerAnimated(true)
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
        
        self.openLight(!isLightOpened)
    }
    
    //MARK:图片
    @IBAction func QRCodePhotosBtnClick(sender: UIButton) {
     
        self.openPhotoLibrary()
    }
    
    /**
     执行动画
     */
    func startAnimation()
    {
        // 让约束从顶部开始
        self.qrcodeLineTop.constant = 0
        self.view.layoutIfNeeded()
        
        //
        weak var weakSelf = self
        UIView.animateWithDuration(3.0, animations: { () -> Void in
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
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        do{
            // 创建输入对象
            let input = try AVCaptureDeviceInput(device: device)
            return input
        }catch
        {
            print(error)
            return nil
        }
    }()
    
    
    // 拿到输出对象
    private lazy var output: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    
    // 创建预览图层
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        layer.frame = UIScreen.mainScreen().bounds
        return layer
    }()
    
    
    // 创建用于绘制边线的图层
    private lazy var drawLayer: CALayer = {
        let layer = CALayer()
        layer.frame = UIScreen.mainScreen().bounds
        return layer
    }()
    
}



//MARK:--打开闪光灯的方法
extension QRCodeViewController{

    ///判断闪光灯是否打开
    private func isLightOpened()-> Bool{
    
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if !device.hasTorch{
        
            return false
            
        }else{
        
            if device.torchMode == AVCaptureTorchMode.On{//闪光灯已经打开
            
                return true
            
            }else{
            
                return false
            }
        
        }
    }
    
    ///打开闪光灯的方法
    private func openLight(open:Bool){
    
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if !device.hasTorch{
        
            UIAlertView(title: "提示", message: "闪光灯故障", delegate: nil, cancelButtonTitle: "确定").show()
            
        }else{
        
            if open{//打开
                
                if  device.torchMode != AVCaptureTorchMode.On || device.flashMode != AVCaptureFlashMode.On{
    
                    do{
                        try device.lockForConfiguration()
                        device.torchMode = AVCaptureTorchMode.On
                        device.flashMode = AVCaptureFlashMode.On
                        device.unlockForConfiguration()
                        
                    }catch
                    {
                        print(error)
                        
                    }
                }
                
            
            }else{//关闭闪光灯
        
                if  device.torchMode != AVCaptureTorchMode.Off || device.flashMode != AVCaptureFlashMode.Off{
                    
                    do{
                        try device.lockForConfiguration()
                        device.torchMode = AVCaptureTorchMode.Off
                        device.flashMode = AVCaptureFlashMode.Off
                        device.unlockForConfiguration()
                        
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
extension QRCodeViewController:UIAlertViewDelegate{

    /**
     扫描二维码
     */
    private func startScan(){
        
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
        output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        // 添加预览图层
        view.layer.insertSublayer(previewLayer, atIndex: 0)
        // 添加绘制图层到预览图层上
        previewLayer.addSublayer(drawLayer)
        // 6.告诉session开始扫描
        session.startRunning()
    }
    
    // 只要解析到数据就会调用
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!)
    {
        
        // 1.获取扫描到的数据
        // 注意: 要使用stringValue
        let result = metadataObjects.last?.stringValue
        if result != nil{
    
            UIAlertView(title: "提示", message: "扫描结果为:\(result!)", delegate: self, cancelButtonTitle: "确定").show()
            session.stopRunning()
    
        }
    }
    
    //MARK: UIAlertViewDelegate 代理方法
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        session.startRunning()
    }
    
}

//MARK:--访问相册和从相册解析二维码的方法
extension QRCodeViewController:UIImagePickerControllerDelegate,UINavigationControllerDelegate{

    ///打开相册的方法
    private func openPhotoLibrary() {
        
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.presentViewController(picker, animated: true, completion: nil)
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let type = (info as NSDictionary).objectForKey(UIImagePickerControllerMediaType) as! String
        session.stopRunning()
        if type == "public.image"
        {
            let image = (info as NSDictionary).objectForKey(UIImagePickerControllerOriginalImage) as! UIImage
            self.photoLibraryImage = image
            //识别二维码的方法
            let result = image.decodeQRImageWith(image)
            //跳转的方法
            if result != nil{
            
                UIAlertView(title: "提示", message: "扫描结果为:\(result!)", delegate: self, cancelButtonTitle: "确定").show()
                
            }else{
            
                UIAlertView(title: "提示", message: "不能识别的类型", delegate: self, cancelButtonTitle: "确定").show()
            }
        
        }
        
        self.dismissViewControllerAnimated(true) { () -> Void in}
    }
    
}


