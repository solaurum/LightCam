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
        0: "Sakura Pink", 1: "Golden Hour", 2: "Aurora Purple",
        3: "Coral Reef", 4: "Glacier Blue", 5: "Matcha Mist", 6: "Smoky Silver",
        7: "Deep Sea Glow"
    ]
    private let zhPresetNames: [Int: String] = [
        0: "樱花微醺粉", 1: "黄金时刻奶黄", 2: "极光紫薰衣草",
        3: "珊瑚礁蜜桃", 4: "冰川蓝冰白", 5: "抹茶雾浅绿", 6: "烟灰银珍珠白",
        7: "深海夜光深蓝"
    ]
    private let koPresetNames: [Int: String] = [
        0: "사쿠라 핑크", 1: "골든 아워", 2: "오로라 퍼플",
        3: "코랄 리프", 4: "글레이셔 블루", 5: "말차 미스트", 6: "스모키 실버",
        7: "딥씨 글로우"
    ]
    private let jaPresetNames: [Int: String] = [
        0: "桜微醺ピンク", 1: "ゴールデンアワー", 2: "オーロラパープル",
        3: "コーラルリーフ", 4: "グレイシャーブルー", 5: "抹茶ミスト", 6: "スモーキーシルバー",
        7: "ディープシーグロー"
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

        // Split direction
        "split_direction": [.english: "Split Direction", .chinese: "双色方向", .korean: "분할 방향", .japanese: "分割方向"],
        "split_horizontal": [.english: "L-R", .chinese: "左右", .korean: "좌우", .japanese: "左右"],
        "split_vertical": [.english: "T-B", .chinese: "上下", .korean: "상하", .japanese: "上下"],
        "split_diagonal_left": [.english: "Diag ↙", .chinese: "斜角↙", .korean: "대각 ↙", .japanese: "斜め↙"],
        "split_diagonal_right": [.english: "Diag ↘", .chinese: "斜角↘", .korean: "대각 ↘", .japanese: "斜め↘"],

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
