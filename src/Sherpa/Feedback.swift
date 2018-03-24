//
// Copyright © 2017 Daniel Farrelly
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// *	Redistributions of source code must retain the above copyright notice, this list
//		of conditions and the following disclaimer.
// *	Redistributions in binary form must reproduce the above copyright notice, this
//		list of conditions and the following disclaimer in the documentation and/or
//		other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation
import MessageUI
import Social
import SafariServices

internal protocol Feedback {
	
	var label: String { get }
	
	var detail: String { get }
	
	var viewController: UIViewController? { get }
	
	init?(string: String)
	
}

internal class FeedbackEmail: NSObject, Feedback, MFMailComposeViewControllerDelegate {
	
	let name: String?
	
	let email: String
	
	required init?(string: String) {
		let regex = try! NSRegularExpression(pattern: "^\\s*((\"?([^\"]*)\"?|.*)\\s)?<?(.+?@.+?)>?\\s*$", options: [])
		
		if let match = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)).first {
            let nameRange = match.range(at: 3)
			self.name = nameRange.location != NSNotFound ? (string as NSString).substring(with: nameRange) : nil
			
            let emailRange = match.range(at: 4)
			self.email = emailRange.location != NSNotFound ? (string as NSString).substring(with: emailRange) : ""
		}
		else {
			self.name = nil
			self.email = ""
		}
		
		if self.email.isEmpty {
			return nil
		}
	}
	
	var label: String {
		return NSLocalizedString("Email", comment: "FEEDBACK_LABEL_EMAIL")
	}
	
	var detail: String {
		return self.email
	}
	
	var viewController: UIViewController? {
		guard MFMailComposeViewController.canSendMail() else {
			return nil
		}
		
		let bundle = Bundle.main
		let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? bundle.object(forInfoDictionaryKey: "CFBundleName") ?? ""
		let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? ""
		let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") ?? ""
		let subject = "Feedback for \(name) v\(version) (\(build))"
		
		let viewController = MFMailComposeViewController()
		viewController.mailComposeDelegate = self
		viewController.setToRecipients([self.fullString])
		viewController.setSubject(subject)
	
		return viewController
	}
	
	var fullString: String {
		if let name = self.name {
			return "\(name) <\(self.email)>"
		}
		
		return self.email
	}

	internal func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true, completion: nil)
	}
	
}

internal struct FeedbackTwitter: Feedback {
	
	let handle: String
	
	init?(string: String) {
		let characterSet = NSMutableCharacterSet.whitespaceAndNewline()
		characterSet.addCharacters(in: "@＠")
		self.handle = string.trimmingCharacters(in: characterSet as CharacterSet)
		
		let regex = "^[a-zA-Z0-9_]{1,20}$"
		if self.handle.isEmpty || self.handle.range(of: regex, options: .regularExpression) == nil {
			return nil
		}
	}
	
	var label: String {
		return NSLocalizedString("Twitter", comment: "FEEDBACK_LABEL_TWITTER")
	}
	
	var detail: String {
		return "@\(self.handle)"
	}

	var viewController: UIViewController? {
		if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeTwitter) {
			let viewController = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
			viewController?.setInitialText("@\(self.handle) ")
			return viewController
		}
			
		else if #available(iOSApplicationExtension 9.0, *) {
			let url = URL(string: "https://twitter.com/\(self.handle)")!
			return SFSafariViewController(url: url)
		}
		
		return nil
	}
	
}
