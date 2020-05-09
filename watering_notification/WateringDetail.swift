//
//  WateringDetail.swift
//  watering_notification
//
//  Created by donchan922 on 2020/05/09.
//  Copyright © 2020 Daiki Tsukuda. All rights reserved.
//

import SwiftUI
import CoreData
import UserNotifications

struct WateringDetail: View {
    @Environment(\.managedObjectContext) var context
    @Environment(\.presentationMode) var presentationMode
    @State private var plantName = ""
    @State private var term = 1
    @State private var nextTime = Date()
    @State private var icon = "plant_01"
    @State private var isFirstAppear = true
    @State private var isShowingSheet = false
    
    var watering: Watering
    
    var body: some View {
        Form {
            Section(header: Text("植物の名前")) {
                TextField("", text: $plantName)
                    .onAppear(perform: {
                        self.plantName = self.watering.plantName!
                    })
            }
            Section(header: Text("水やりの間隔")) {
                Picker(selection: $term, label: Text("")) {
                    ForEach(1...100, id: \.self) { index in
                        Text("\(index)日ごと")
                    }
                }
                .onAppear(perform: {
                    if self.isFirstAppear {
                        self.term = Int(self.watering.term)
                    }
                    self.isFirstAppear = false
                })
            }
            Section(header: Text("水やりの時間")) {
                DatePicker(selection: $nextTime, displayedComponents: [.hourAndMinute]) {
                    Text("")
                }
                .onAppear(perform: {
                    self.nextTime = self.watering.nextTime!
                })
            }
            Section(header: Text("アイコン")) {
                VStack {
                    HStack {
                        IconImage(icon: $icon, iconName: "plant_01")
                        IconImage(icon: $icon, iconName: "plant_02")
                        IconImage(icon: $icon, iconName: "plant_03")
                        IconImage(icon: $icon, iconName: "plant_04")
                    }
                    HStack {
                        IconImage(icon: $icon, iconName: "plant_05")
                        IconImage(icon: $icon, iconName: "plant_06")
                        IconImage(icon: $icon, iconName: "plant_07")
                        IconImage(icon: $icon, iconName: "plant_08")
                    }
                    HStack {
                        IconImage(icon: $icon, iconName: "plant_09")
                        IconImage(icon: $icon, iconName: "plant_10")
                        IconImage(icon: $icon, iconName: "plant_11")
                        IconImage(icon: $icon, iconName: "plant_12")
                    }
                }
                .onAppear(perform: {
                    self.icon = self.watering.icon!
                })
            }
            Section(header: Text("")) {
                Button(action: {
                    self.isShowingSheet = true
                }) {
                    Text("削除")
                        .foregroundColor(.red)
                }
                .actionSheet(isPresented: $isShowingSheet) {
                    ActionSheet(
                        title: Text("登録内容を削除しますか？"),
                        buttons: [
                            .destructive(Text("削除"), action: {
                                self.deleteWatering()
                                self.presentationMode.wrappedValue.dismiss()
                            }),
                            .cancel(Text("キャンセル"))
                        ]
                    )
                }
            }
        }
        .navigationBarTitle(Text("登録内容"), displayMode: .inline)
        .navigationBarItems(
            trailing: Button(action: {
                self.updateWatering()
                self.presentationMode.wrappedValue.dismiss()
            }) {
                Text("完了")
            }.disabled(plantName.isEmpty)
        )
    }
    
    func updateWatering() {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: nextTime)
        var nextTime = Calendar.current.date(byAdding: .day, value: term, to: startOfDay)
        nextTime = Calendar.current.date(byAdding: .hour, value: timeComponents.hour!, to: nextTime!)
        nextTime = Calendar.current.date(byAdding: .minute, value: timeComponents.minute!, to: nextTime!)
        
        // update data
        watering.setValue(plantName, forKey: "plantName")
        watering.setValue(Int16(term), forKey: "term")
        watering.setValue(nextTime, forKey: "nextTime")
        watering.setValue(icon, forKey: "icon")
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }

        // update notification
        let content = UNMutableNotificationContent()
        content.title = "🌱水やりのお知らせ"
        content.body = "\(plantName)に水やりする時間です"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: now.distance(to: nextTime!), repeats: true)
        let request = UNNotificationRequest(identifier: watering.id!.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func deleteWatering() {
        // delete notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [watering.id!.uuidString])
        
        // delete data
        context.delete(watering)
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

struct WateringDetail_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let watering = Watering(context: context)
        watering.id = UUID()
        watering.plantName = "トマト"
        watering.term = 1
        watering.nextTime = Date()
        watering.icon = "plant_01"
        watering.createdAt = Date()
        return WateringDetail(watering: watering).environment(\.managedObjectContext, context)
    }
}
