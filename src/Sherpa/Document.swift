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

import UIKit

internal class Document {
	
	// MARK: Customising appearance
	
	internal var tintColor: UIColor? = UINavigationBar.appearance().tintColor
	
	internal var articleBackgroundColor: UIColor = UIColor.white
	
	internal var articleTextColor: UIColor = UIColor.darkText
	
	internal var articleCellClass = UITableViewCell.self
	
	internal var feedbackCellClass = UITableViewCell.self
	
	// MARK: Feedback points.
	
	internal var feedback: [Feedback] = []
	
	// MARK: Instance life cycle
	
	internal let fileURL: URL?
	
	internal var sections: [Section] = []
	
	internal init(fileAtURL fileURL: URL) {
		self.fileURL = fileURL
		self._loadFromFile()
	}
	
	internal init(dictionary: [String: Any]) {
		self.fileURL = nil
		self._load(from: dictionary)
	}
	
	internal init(array: [[String: Any]]) {
		self.fileURL = nil
		self._load(from: array)
	}
	
	// MARK: Retrieving content
	
	internal func section(_ index: Int) -> Section? {
		if index < 0 || index >= self.sections.count { return nil }
		
		return self.sections[index]
	}
	
	internal func article(_ key: String) -> Article? {
		return self.sections.flatMap({ $0.articles }).filter({ key == $0.key }).first
	}
	
	// MARK: Utilities

	fileprivate func _loadFromFile() {
		do {
			guard let fileURL = self.fileURL, let data = try? Data(contentsOf: fileURL) else {
				return
			}
			
			let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
			
			if let dictionary = json as? [String:Any] {
				self._load(from: dictionary)
			}
				
			else if let array = json as? [[String:Any]] {
				self._load(from: array)
			}
		}
		catch {
			return
		}
	}
	
	fileprivate func _load(from dictionary: [String:Any]) {
		// Feedback
		if let string = dictionary["feedback_email"] as? String, let email = FeedbackEmail(string: string) {
			self.feedback.append(email)
		}

		if let string = dictionary["feedback_twitter"] as? String, let twitter = FeedbackTwitter(string: string) {
			self.feedback.append(twitter)
		}
		
		// Sections
		self._load(from: dictionary["entries"] as? [[String:Any]] ?? [])
	}
	
	fileprivate func _load(from array: [[String:Any]]) {
        self.sections = array.compactMap({ Section(dictionary: $0) })
	}
	
}
