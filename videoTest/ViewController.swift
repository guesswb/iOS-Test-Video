//
//  ViewController.swift
//  videoTest
//
//  Created by 김기훈 on 2023/04/25.
//

import UIKit
import AVKit
import PhotosUI

class ViewController: UIViewController {

    var player = AVPlayer()
    var playerLayer: AVPlayerLayer!
    
    var playerItemContext = 0
    var isPlaying = false
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var currentTime: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    
    @IBAction func selectButtonTouched(_ sender: UIButton) {
        showPHPicker()
    }
    
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if isPlaying {
            pauseVideo()
        } else {
           playVideo()
        }
    }
    
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
//
//        guard let totalSeconds = self.player.currentItem?.duration.seconds else { return }
//
//        let seekTime = CMTime(value: CMTimeValue(Double(sender.value) * totalSeconds), timescale: 1)
//
//        self.player.seek(to: seekTime) { _ in
//
//            let minutes = Int(Double(sender.value) * totalSeconds) / 60
//            let seconds = Int(Double(sender.value) * totalSeconds) % 60
//            let timeFormatString = String(format: "%02d : %02d", minutes, seconds)
//
//            self.currentTime.text = timeFormatString
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func showPHPicker() {
        var config = PHPickerConfiguration()
        config.filter = .videos
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func playVideo() {
        player.play()
        isPlaying.toggle()
        playPauseButton.setTitle("Pause", for: .normal)
    }
    
    func pauseVideo() {
        player.pause()
        isPlaying.toggle()
        playPauseButton.setTitle("Play", for: .normal)
    }
    
    func changeCurrentTime() {
        guard let totalSeconds = self.player.currentItem?.duration.seconds else { return }
        
        let resultSeconds = Int(Double(slider.value) * totalSeconds)
        
        let minutes = resultSeconds / 60
        let seconds = resultSeconds % 60
        let timeFormatString = String(format: "%02d : %02d", minutes, seconds)
        
        self.currentTime.text = timeFormatString
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
     
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
     
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            switch status {
            case .readyToPlay:
                print("readyToPlay")
                slider.value = 0
            case .failed:
                print("fail")
            case .unknown:
                print("unknown")
            @unknown default:
                print("fail")
            }
        }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let provider = results.first?.itemProvider else { return }
        
        provider.loadItem(forTypeIdentifier: UTType.movie.identifier) { [weak self] (videoURL, error) in
            guard let self = self, let url = videoURL as? URL else { return }
            
            let asset = AVAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            
            self.player.replaceCurrentItem(with: item)
            self.playerLayer = AVPlayerLayer(player: self.player)
            self.player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &self.playerItemContext)
            self.playerLayer.frame = self.videoView.bounds
            
        
            let interval = CMTime(seconds: 0.01, preferredTimescale: Int32(NSEC_PER_SEC))
            
            self.player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { currentTime in
                guard let duration = self.player.currentItem?.duration else { return }
                
                let currentSeconds = CMTimeGetSeconds(currentTime)
                let totalSeconds = CMTimeGetSeconds(duration)
                
                if currentSeconds == totalSeconds {
                    self.pauseVideo()
                    self.player.seek(to: CMTime(seconds: 0, preferredTimescale: Int32(NSEC_PER_SEC)))
                } else {
                    self.slider.value = Float(currentTime.seconds / duration.seconds)
                }
                
                self.changeCurrentTime()
            })
            
            Task {
                self.videoView.layer.addSublayer(self.playerLayer)
            }
        }
    }
}
