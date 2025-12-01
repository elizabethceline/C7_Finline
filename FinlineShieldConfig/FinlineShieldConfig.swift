//
//  ShieldConfigurationExtension.swift
//  FinlineShieldConfig
//
//  Created by Gabriella Natasya Pingky Davis on 22/11/25.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(named: "ad"),
            title: ShieldConfiguration.Label(
                text: "Stay Focus!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session. Return to Finline and keep fishing!",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: .white
            ),
            primaryButtonBackgroundColor: .finlinePrimary
        )
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(named: "ad"),
            title: ShieldConfiguration.Label(
                text: "Stay Focus!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session. Return to Finline and keep fishing!",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: .white
            ),
            primaryButtonBackgroundColor: .finlinePrimary
        )
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(named: "ad"),
            title: ShieldConfiguration.Label(
                text: "Stay Focus!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session. Return to Finline and keep fishing!",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: .white
            ),
            primaryButtonBackgroundColor: .finlinePrimary
        )
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor.systemBackground,
            icon: UIImage(named: "ad"),
            title: ShieldConfiguration.Label(
                text: "Stay Focus!",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked during your focus session. Return to Finline and keep fishing!",
                color: .white
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Go Back",
                color: .white
            ),
            primaryButtonBackgroundColor: .finlinePrimary
        )
    }
}
