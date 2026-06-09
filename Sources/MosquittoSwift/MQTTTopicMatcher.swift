enum MQTTTopicMatcher {
    static func matches(filter: String, topic: String) -> Bool {
        let filterLevels = filter.split(separator: "/", omittingEmptySubsequences: false)
        let topicLevels = topic.split(separator: "/", omittingEmptySubsequences: false)

        var topicIndex = 0
        for filterIndex in filterLevels.indices {
            let level = filterLevels[filterIndex]
            if level == "#" {
                return filterIndex == filterLevels.index(before: filterLevels.endIndex)
            }
            guard topicIndex < topicLevels.count else { return false }
            if level != "+", level != topicLevels[topicIndex] {
                return false
            }
            topicIndex += 1
        }

        return topicIndex == topicLevels.count
    }
}