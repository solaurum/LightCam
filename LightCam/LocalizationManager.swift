import SwiftUI

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chinese = "zh-Hans"
    case korean = "ko"
    case japanese = "ja"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "简体中文"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        }
    }

    var shortName: String {
        switch self {
        case .english: return "EN"
        case .chinese: return "中文"
        case .korean: return "한글"
        case .japanese: return "日本語"
        }
    }
}

class LocalizationManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        currentLanguage = AppLanguage(rawValue: raw) ?? .english
    }

    // MARK: - Preset Names

    func presetName(for preset: LightPreset) -> String {
        if preset.isCustom { return preset.name }
        let id = preset.id
        switch currentLanguage {
        case .english:
            return enPresetNames[id] ?? preset.name
        case .chinese:
            return zhPresetNames[id] ?? preset.name
        case .korean:
            return koPresetNames[id] ?? preset.name
        case .japanese:
            return jaPresetNames[id] ?? preset.name
        }
    }

    // MARK: - UI Strings

    func string(_ key: String) -> String {
        strings[key]?[currentLanguage] ?? key
    }

    // MARK: - Dictionaries

    private let enPresetNames: [Int: String] = [
        0: "Studio White", 1: "Golden Hour", 2: "Fireside",
        3: "Morning Mist", 4: "Honey Glow", 5: "Rose Blush", 6: "Twilight Haze",
        7: "Blue Hour"
    ]
    private let zhPresetNames: [Int: String] = [
        0: "影棚白光", 1: "落日余晖", 2: "炉火暖光",
        3: "晨雾柔光", 4: "蜂蜜琥珀", 5: "玫瑰绯红", 6: "暮光紫霞",
        7: "蓝调时刻"
    ]
    private let koPresetNames: [Int: String] = [
        0: "스튜디오 화이트", 1: "골든 아워", 2: "파이어사이드",
        3: "아침 안개", 4: "허니 글로우", 5: "로즈 블러시", 6: "트와일라잇 헤이즈",
        7: "블루 아워"
    ]
    private let jaPresetNames: [Int: String] = [
        0: "スタジオホワイト", 1: "ゴールデンアワー", 2: "ファイヤーサイド",
        3: "朝霧", 4: "ハニーグロー", 5: "ローズブラッシュ", 6: "トワイライトヘイズ",
        7: "ブルーアワー"
    ]

    private let strings: [String: [AppLanguage: String]] = [
        // Preset picker
        "light_presets": [.english: "Light Presets", .chinese: "光效预设", .korean: "라이트 프리셋", .japanese: "ライトプリセット"],
        "built_in": [.english: "Built-in", .chinese: "内置", .korean: "내장", .japanese: "内蔵"],
        "custom": [.english: "Custom", .chinese: "自定义", .korean: "커스텀", .japanese: "カスタム"],
        "add_custom_preset": [.english: "Add Custom Preset", .chinese: "添加自定义光效", .korean: "커스텀 프리셋 추가", .japanese: "カスタムプリセットを追加"],
        "delete_preset": [.english: "Delete Preset", .chinese: "删除光效", .korean: "프리셋 삭제", .japanese: "プリセットを削除"],

        // Photo preview
        "saved_to_library": [.english: "Saved to Photo Library", .chinese: "已保存到相册", .korean: "사진 보관함에 저장됨", .japanese: "フォトライブラリに保存しました"],

        // Camera permission
        "camera_permission_denied": [.english: "Camera Permission Denied", .chinese: "摄像头权限被拒绝", .korean: "카메라 권한 거부됨", .japanese: "カメラ権限が拒否されました"],
        "open_settings": [.english: "Open Settings", .chinese: "打开设置", .korean: "설정 열기", .japanese: "設定を開く"],
        "cancel": [.english: "Cancel", .chinese: "取消", .korean: "취소", .japanese: "キャンセル"],
        "camera_permission_message": [
            .english: "Please allow camera access in System Settings to use LightCam",
            .chinese: "请在系统设置中允许补光相机访问摄像头",
            .korean: "시스템 설정에서 LightCam의 카메라 접근을 허용해주세요",
            .japanese: "システム設定でLightCamのカメラアクセスを許可してください"
        ],

        // Camera loading / errors
        "starting_camera": [.english: "Starting camera...", .chinese: "正在启动摄像头...", .korean: "카메라 시작 중...", .japanese: "カメラを起動中..."],
        "photo_processing_failed": [.english: "Photo processing failed", .chinese: "照片处理失败", .korean: "사진 처리 실패", .japanese: "写真の処理に失敗しました"],

        // Color editor
        "new_custom_preset": [.english: "New Custom Preset", .chinese: "新建自定义光效", .korean: "새 커스텀 프리셋", .japanese: "新規カスタムプリセット"],
        "preset_name": [.english: "Preset Name", .chinese: "光效名称", .korean: "프리셋 이름", .japanese: "プリセット名"],
        "name_placeholder": [.english: "Name", .chinese: "名称", .korean: "이름", .japanese: "名前"],
        "color_mode": [.english: "Color Mode", .chinese: "颜色模式", .korean: "색상 모드", .japanese: "カラーモード"],
        "colors": [.english: "Colors", .chinese: "颜色", .korean: "색상", .japanese: "色"],
        "primary_color": [.english: "Primary Color", .chinese: "主颜色", .korean: "기본 색상", .japanese: "メインカラー"],
        "secondary_color": [.english: "Secondary Color", .chinese: "副颜色", .korean: "보조 색상", .japanese: "サブカラー"],
        "preview": [.english: "Preview", .chinese: "预览", .korean: "미리보기", .japanese: "プレビュー"],
        "default_brightness": [.english: "Default Brightness", .chinese: "默认亮度", .korean: "기본 밝기", .japanese: "デフォルトの明るさ"],
        "save": [.english: "Save", .chinese: "保存", .korean: "저장", .japanese: "保存"],

        // Mode names
        "mode_solid": [.english: "Solid", .chinese: "纯色", .korean: "솔리드", .japanese: "ソリッド"],
        "mode_gradient": [.english: "Gradient", .chinese: "渐变", .korean: "그라데이션", .japanese: "グラデーション"],
        "mode_dual": [.english: "Dual", .chinese: "双色", .korean: "듀얼", .japanese: "デュアル"],

        // Language
        "language": [.english: "Language", .chinese: "语言", .korean: "언어", .japanese: "言語"],

        // Color editor
        "new_preset": [.english: "New Preset", .chinese: "新建预设", .korean: "새 프리셋", .japanese: "新規プリセット"],
        "edit_preset": [.english: "Edit Preset", .chinese: "编辑预设", .korean: "프리셋 편집", .japanese: "プリセット編集"],
        "primary": [.english: "Primary", .chinese: "主色", .korean: "기본", .japanese: "メイン"],
        "secondary": [.english: "Secondary", .chinese: "副色", .korean: "보조", .japanese: "サブ"],
        "save_preset": [.english: "Save Preset", .chinese: "保存预设", .korean: "프리셋 저장", .japanese: "プリセット保存"],
        "update": [.english: "Update", .chinese: "更新", .korean: "업데이트", .japanese: "更新"],
    ]
}
