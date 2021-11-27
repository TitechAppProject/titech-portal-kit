import Foundation

extension String {
    func matches(_ pattern: String, options: NSRegularExpression.Options = []) -> [[String]]? {
        return Regex(pattern, options: options).matches(self, start: 1)
    }
    func matches0(_ pattern: String, options: NSRegularExpression.Options = []) -> [[String]]? {
        return Regex(pattern, options: options).matches(self, start: 0)
    }
}

struct Regex {
    let pattern: String
    var options: NSRegularExpression.Options

    init(_ pattern: String, options: NSRegularExpression.Options = []) {
        self.pattern = pattern
        self.options = options
    }

    func matches(_ string: String, start: Int) -> [[String]]? {
        do {
            let results = try NSRegularExpression(pattern: pattern, options: options).matches(in: string, options: .reportProgress, range: NSRange(location: 0, length: string.count))
            var dats: [[String]] = []
            for result in results {
                var datss = [String]()
                for j in start ..< result.numberOfRanges {
                    if result.range(at: j).length == 0 {
                        datss += [""]
                        continue
                    }
                    datss += [(string as NSString).substring(with: result.range(at: j))]
                }
                dats += [datss]
            }
            return dats

        } catch {
            return nil
        }
    }
}
