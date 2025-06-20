//
//  MailComposeView.swift
//
//
//  Created by Edon Valdman on 3/2/23.
//

import Messages
import MessageUI
import SwiftUI

/// To be notified of the `View`'s completion and to obtain its completion result, register as an observer of the `Notifiction.Name.MailComposeViewDidFinish` notification.
public struct MailComposeView: UIViewControllerRepresentable {
    public typealias CompletionHandler = (_ result: MFMailComposeResult, _ error: Error?) -> Void
    
    public var initialMailInfo: MailInfo
    public var completionHandler: CompletionHandler?
    
    private var attachments: [AttachmentData] = []
    
    /// Creates a new ``MailComposeView``.
    ///
    /// - Note: If you need the completion result elsewhere in your codebase, you can observe the `.MailComposeViewDidFinish` notification. Upon receiving this notification, query its `userInfo` dictionary with the ``MailComposeView/DidFinishResultKey`` and ``MailComposeView/DidFinishErrorKey`` keys. They will be of [MessageComposeResult](https://developer.apple.com/documentation/messageui/messagecomposeresult) and `Error?` types.
    /// - Parameters:
    ///   - initialMailInfo: Sets the initial values of the ``MailComposeView``.
    ///   - completionHandler: A handler that is called when the view is closed.
    public init(_ initialMailInfo: MailInfo, _ completionHandler: CompletionHandler? = nil) {
        self.initialMailInfo = initialMailInfo
        self.completionHandler = completionHandler
    }
    
    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = context.coordinator
        
        composeVC.setSubject(initialMailInfo.subject)
        composeVC.setToRecipients(initialMailInfo.toRecipients)
        composeVC.setCcRecipients(initialMailInfo.ccRecipients)
        composeVC.setBccRecipients(initialMailInfo.bccRecipients)
        composeVC.setMessageBody(initialMailInfo.body,
                                 isHTML: initialMailInfo.bodyIsHTML)
        composeVC.setPreferredSendingEmailAddress(initialMailInfo.preferredSendingEmailAddress)
        
        for a in attachments {
            composeVC.addAttachmentData(a.attachment,
                                        mimeType: a.mimeType,
                                        fileName: a.fileName)
        }
        
        return composeVC
    }
    
    public func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    public func makeCoordinator() -> MCCoordinator {
        MCCoordinator(self)
    }
    
    public mutating func addAttachments(_ attachments: [AttachmentData]) {
        self.attachments.append(contentsOf: attachments)
    }
}

// MARK: - MFMailComposeViewControllerDelegate

public extension MailComposeView {
    static let DidFinishResultKey = "SwiftUIMessage.MailComposeViewDidFinishResultKey"
    static let DidFinishErrorKey = "SwiftUIMessage.MailComposeViewDidFinishErrorKey"
    
    class MCCoordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.completionHandler?(result, error)
            
            NotificationCenter.default.post(
                name: .MailComposeViewDidFinish,
                object: parent,
                userInfo: [
                    MailComposeView.DidFinishResultKey: result,
                    MailComposeView.DidFinishErrorKey: error as Any
                ]
            )
            
            controller.dismiss(animated: true)
        }
    }
}

// MARK: - Initial Message Info

public extension MailComposeView {
    /// Used to set mail fields programmatically.
    struct MailInfo {
        public init(subject: String? = nil, toRecipients: [String]? = nil, ccRecipients: [String]? = nil, bccRecipients: [String]? = nil, body: String = "", bodyIsHTML: Bool = false, preferredSendingEmailAddress: String? = nil) {
            self.subject = subject ?? ""
            self.toRecipients = toRecipients
            self.ccRecipients = ccRecipients
            self.bccRecipients = bccRecipients
            self.body = body
            self.bodyIsHTML = bodyIsHTML
            self.preferredSendingEmailAddress = preferredSendingEmailAddress ?? ""
        }
        
        /// Sets the initial text for the subject line of the email.
        public var subject: String = ""
        
        /// Sets the initial recipients to include in the email’s To field.
        ///
        /// An array of `String` objects, each containing the email address of a single recipient.
        ///
        /// This does not filter out duplicate email addresses, so if duplicates are present, multiple copies of the email message may be sent to the same address.
        public var toRecipients: [String]?
        
        /// Sets the initial recipients to include in the email’s Cc field.
        ///
        /// An array of `String` objects, each containing the email address of a single recipient.
        ///
        /// This does not filter out duplicate email addresses, so if duplicates are present, multiple copies of the email message may be sent to the same address.
        public var ccRecipients: [String]?
        
        /// Sets the initial recipients to include in the email’s Bcc field.
        ///
        /// An array of `String` objects, each containing the email address of a single recipient.
        ///
        /// This does not filter out duplicate email addresses, so if duplicates are present, multiple copies of the email message may be sent to the same address.
        /// > Important: ``MailComposeView`` ignores calls to this method in Mac apps built with Mac Catalyst.
        public var bccRecipients: [String]?
        
        /// The initial body text to include in the email.
        ///
        /// The text is interpreted as either plain text or HTML, depending on the value of the ``MailComposeView/MailInfo/bodyIsHTML`` parameter.
        public var body: String = ""
        
        /// Specifies if ``MailComposeView/MailInfo/body`` contains plain text or HTML.
        ///
        /// `true` if ``MailComposeView/MailInfo/body`` contains HTML content, or `false` if it contains plain text.
        ///
        /// If the user has a signature file, the body content is inserted immediately before the signature. If you want to include images with your content, you must attach the images separately using the `MailComposeView.withAttachments(_:)` method.
        public var bodyIsHTML: Bool = false
        
        /// The preferred email address to use in the From field, if such an address is available.
        ///
        /// If the user does not have an account with a preferred address set up, the default account is used instead.
        public var preferredSendingEmailAddress: String = ""
    }
}

// MARK: - Convenience Access to Class Functions

public extension MailComposeView {
    /// Returns a Boolean that indicates whether the current device is able to send email.
    ///
    /// You should call this method before attempting to display the mail composition interface. If it returns false, you must not display the mail composition interface.
    /// - Returns: `true` if the device is configured for sending email or `false` if it is not.
    static func canSendMail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }
}

struct MailComposeView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            MailComposeView(.init(
                //                recipients: [
//                "7863273437",
//                "edon@valdman.works"
//            ],
//                                  body: "Test"
            ))
            .ignoresSafeArea()
        } else {
            // Fallback on earlier versions
        }
    }
}
