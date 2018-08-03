import UIKit

let keyword = "still life"
let key = "t44zjhyudjf2xjhvckumennq"
let baseUrl = "https://api.walmartlabs.com/v1/search?query=\(keyword)&format=json&apiKey=\(key)".addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!
let url = URL(string: baseUrl)
