//
//  PouchWidgetBundle.swift
//  PouchWidget
//
//  Created by dzbanek on 19/05/2026.
//

import WidgetKit
import SwiftUI

@main
struct PouchWidgetBundle: WidgetBundle {
    var body: some Widget {
        PouchWidget()
        PouchWidgetLiveActivity()
    }
}
