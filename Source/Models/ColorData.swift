import UIKit

enum ColorType: String, Codable {
	case solid
	case gradient
	case split
}

struct ColorData: Codable, Equatable {
	let type: ColorType
	var primaryColor: UIColor
	var secondaryColor: UIColor?
	var gradientAngle: Double?

	enum CodingKeys: String, CodingKey {
		case type, primaryColor, secondaryColor, gradientAngle
	}

	init(type: ColorType, primaryColor: UIColor, secondaryColor: UIColor?, gradientAngle: Double?) {
		self.type = type
		self.primaryColor = primaryColor
		self.secondaryColor = secondaryColor
		self.gradientAngle = gradientAngle
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		type = try container.decode(ColorType.self, forKey: .type)
		let primaryHex = try container.decode(String.self, forKey: .primaryColor)
		primaryColor = UIColor(hex: primaryHex)
		if let secondaryHex = try container.decodeIfPresent(String.self, forKey: .secondaryColor) {
			secondaryColor = UIColor(hex: secondaryHex)
		} else {
			secondaryColor = nil
		}
		gradientAngle = try container.decodeIfPresent(Double.self, forKey: .gradientAngle)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type, forKey: .type)
		try container.encode(primaryColor.hexString, forKey: .primaryColor)
		if let secondary = secondaryColor {
			try container.encode(secondary.hexString, forKey: .secondaryColor)
		}
		try container.encodeIfPresent(gradientAngle, forKey: .gradientAngle)
	}

	static func solid(_ color: UIColor) -> ColorData {
		ColorData(type: .solid, primaryColor: color, secondaryColor: nil, gradientAngle: nil)
	}

	static func gradient(primary: UIColor, secondary: UIColor, angle: Double = 135) -> ColorData {
		ColorData(type: .gradient, primaryColor: primary, secondaryColor: secondary, gradientAngle: angle)
	}

	static func split(primary: UIColor, secondary: UIColor) -> ColorData {
		ColorData(type: .split, primaryColor: primary, secondaryColor: secondary, gradientAngle: nil)
	}
}
