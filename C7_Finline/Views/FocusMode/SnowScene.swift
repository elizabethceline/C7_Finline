//
//  SnowScene.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 18/11/25.
//


import SpriteKit

class SnowScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        if let snow = SKEmitterNode(fileNamed: "SnowParticle.sks") {
            snow.position = CGPoint(x: size.width / 2, y: size.height)
            snow.particlePositionRange = CGVector(dx: size.width, dy: 0)
            snow.zPosition = 1
            addChild(snow)
        }
    }

    override func sceneDidLoad() {
        scaleMode = .resizeFill
    }
}
