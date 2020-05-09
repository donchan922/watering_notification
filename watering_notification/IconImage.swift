//
//  IconImage.swift
//  watering_notification
//
//  Created by donchan922 on 2020/05/09.
//  Copyright © 2020 Daiki Tsukuda. All rights reserved.
//

import SwiftUI

struct IconImage: View {
    @Binding var icon: String
    var iconName = ""

    var body: some View {
        Image(iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .border(icon == iconName ? Color.green : Color.clear, width: 3)
            .onTapGesture(perform: {
                self.icon = self.iconName
            })
    }
}

struct IconImage_Previews: PreviewProvider {
    static var previews: some View {
        IconImage(icon: .constant("plant_01"), iconName: "plant_01")
    }
}
