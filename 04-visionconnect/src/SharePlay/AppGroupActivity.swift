import GroupActivities
import SwiftUI

struct AppGroupActivity: GroupActivity {
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = String(localized: "MixedSpace")
        metadata.type = .generic
        metadata.previewImage = UIImage(resource: .wholeIcon).cgImage
        return metadata
    }
}
