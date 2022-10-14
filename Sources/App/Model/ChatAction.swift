//
//  File.swift
//  
//
//  Created by Evgenii Kolgin on 14.10.2022.
//

import Foundation

enum ChatAction: String {
   case typing = "typing"
   case upload_photo = "upload_photo"
   case upload_video = "upload_video"
   case record_video = "record_video"
   case upload_audio = "upload_audio"
   case record_audio = "record_audio"
   case upload_document = "upload_document"
   case find_location = "find_location"
   case upload_video_note = "upload_video_note"
   case record_video_note = "record_video_note"
}
