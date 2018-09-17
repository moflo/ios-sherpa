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
import MessageUI
import Social
import SafariServices

internal class DataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
	
	// MARK: Instance life cycle
	
	internal let tableView: UITableView
	
	internal let document: Document
	
	internal let bundle: Bundle
	
	internal init(tableView: UITableView, document: Document, bundle: Bundle = .main) {
		self.tableView = tableView
		self.document = document
		self.bundle = bundle
		
		if let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
			self.buildNumber = Int(buildNumber)
		}
		
		super.init()
		self.applyFilter()
	}
	
	fileprivate var sections: [Section] {
		get { return self.document.sections }
	}
	
	// MARK: Altering the visible data
	
	internal var sectionTitle: String? {
		didSet{ self.applyFilter() }
	}
	
	internal var query: String? {
		didSet{ self.applyFilter() }
	}
	
	internal var filter: ((Article) -> Bool)? {
		didSet{ self.applyFilter() }
	}
	
	internal var buildNumber: Int? {
		didSet{ self.applyFilter() }
	}
	
	internal var filteredSections: [Section] = []
	
	fileprivate func applyFilter() {
		var sections = self.sections
		
		if let query = self.query {
			sections = sections.flatMap({ $0.section(query) })
		}
		
		if let filter = self.filter {
			sections = sections.flatMap({ $0.section(filter) })
		}
		
		if let buildNumber = self.buildNumber {
			sections = sections.flatMap({ $0.section(buildNumber) })
		}
		
		if let sectionTitle = self.sectionTitle {
			let articles = sections.flatMap({ $0.articles })
			
			if articles.count > 0 {
				sections = [Section(title: sectionTitle, detail: nil, articles: articles)]
			}
			else {
				sections = []
			}
		}
		
		self.filteredSections = sections
	}
	
	// MARK: Accessing data
	
	internal func section(_ index: Int) -> Section? {
		if index < 0 || index >= self.filteredSections.count { return nil }
		
		return self.filteredSections[index]
	}
	
	internal func article(_ indexPath: IndexPath) -> Article? {
		guard let section = self.section(indexPath.section) else { return nil }
		
		if indexPath.row < 0 || indexPath.row >= section.articles.count { return nil }
		
		return section.articles[indexPath.row]
	}
	
	internal func indexPath(_ article: Article) -> IndexPath? {
		for (x, s) in self.filteredSections.enumerated() {
			for (y, a) in s.articles.enumerated() {
				if a.key == article.key && a.title == article.title && a.body == article.body {
					return IndexPath(row: y, section: x)
				}
			}
		}
		
		return nil
	}
	
	// MARK: Feedback
	
	fileprivate var allowFeedback: Bool {
		get{ return self.sectionTitle == nil && self.document.feedback.count > 0 }
	}
	
	fileprivate var indexOfFeedbackSection: Int? {
		get{ return self.allowFeedback ? self.filteredSections.count : nil }
	}
	
	internal func feedback(_ indexPath: IndexPath) -> Feedback? {
		guard indexPath.section == self.indexOfFeedbackSection else { return nil }
		
		if indexPath.row < 0 || indexPath.row >= self.document.feedback.count { return nil }
		
		return self.document.feedback[indexPath.row]
	}
	
	// MARK: Table view data source
	
	@objc func numberOfSections(in tableView: UITableView) -> Int {
		if self.allowFeedback {
			return self.filteredSections.count + 1
		}
		
		return self.filteredSections.count
	}
	
	@objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == self.indexOfFeedbackSection {
			return self.document.feedback.count
		}
		
		return self.section(section)?.articles.count ?? 0
	}
	
	@objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == self.indexOfFeedbackSection {
			return "Feedback"
		}
		
		return self.section(section)?.title
	}
	
	@objc func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		if section == self.indexOfFeedbackSection {
			return nil
		}
		
		return self.section(section)?.detail
	}
	
	@objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: UITableViewCell
		
		if let feedback = self.feedback(indexPath) {
			let reuseIdentifier = "_SherpaFeedbackCell";
			cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? self.document.feedbackCellClass.init(style: .value1, reuseIdentifier: reuseIdentifier)
			
			cell.textLabel!.text = feedback.label
			cell.detailTextLabel!.text = feedback.detail
			
			if feedback.viewController == nil {
				cell.selectionStyle = .none
			}
			else if self.document.feedbackCellClass === UITableViewCell.self {
				cell.selectionStyle = .default
				cell.textLabel!.textColor = self.document.tintColor
			}
		}
			
		else {
			let reuseIdentifier = "_SherpaArticleCell";
			cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? self.document.articleCellClass.init(style: .default, reuseIdentifier: reuseIdentifier)
			
			guard let article = self.article(indexPath) else { return cell }
			
			if self.document.articleCellClass === UITableViewCell.self {
				if #available(iOSApplicationExtension 9.0, *) {
                    cell.textLabel!.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.callout)
				} else {
                    cell.textLabel!.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
				}
				cell.selectionStyle = .default
				cell.textLabel!.textColor = self.document.tintColor
			}
			
			cell.accessoryType = .disclosureIndicator
			cell.textLabel!.numberOfLines = 0
			
			let attributedTitle = NSMutableAttributedString(string: article.title)
			
			if let query = self.query {
				let foregroundColor = cell.textLabel!.textColor
				let bold = cell.textLabel!.font.fontDescriptor.withSymbolicTraits(.traitBold)
				
				var alpha: CGFloat = 0
				foregroundColor?.getRed(nil, green: nil, blue: nil, alpha: &alpha)
				if let foregroundColor = foregroundColor?.withAlphaComponent(0.85) {
                    attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: foregroundColor, range: NSMakeRange(0, attributedTitle.length))
				}
				
				var i = 0
				while true {
					let searchRange = NSMakeRange(i, article.title.count-i)
					let range = (article.title as NSString).range(of: query, options: .caseInsensitive, range: searchRange, locale: Locale.current)
					
					if range.location == NSNotFound { break }
					
                    attributedTitle.addAttribute(NSAttributedString.Key.font, value: UIFont(descriptor: bold!, size: 0.0), range: range)
					if let foregroundColor = foregroundColor {
                        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: foregroundColor, range: range)
					}
					
					i = range.location + range.length
				}
			}
			
			cell.textLabel!.attributedText = attributedTitle
		}
		
		return cell
	}

}
