import Foundation

enum APIEndpoint {
    case foodSearch(query: String)
    case analyzeImage
    case analyzeText
    case submitMealLog
    case profileRefresh
    case me
    case todayDashboard
    case dailyPlan
    case progressSummary
    case chatMessage
    case notificationSettings

    var path: String {
        switch self {
        case .foodSearch: "food-search"
        case .analyzeImage: "analyze-image"
        case .analyzeText: "analyze-text"
        case .submitMealLog: "submit-meal-log"
        case .profileRefresh: "profile-refresh"
        case .me: "profile"
        case .todayDashboard: "dashboard-today"
        case .dailyPlan: "daily-plan"
        case .progressSummary: "progress-summary"
        case .chatMessage: "chat/message"
        case .notificationSettings: "notifications/settings"
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .analyzeText, .analyzeImage, .submitMealLog, .profileRefresh, .me, .todayDashboard, .dailyPlan, .progressSummary, .chatMessage, .notificationSettings:
            true
        case .foodSearch:
            false
        }
    }
}

enum APIError: LocalizedError {
    case missingAccessToken
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .missingAccessToken:
            "Supabase oturumu henüz hazır değil."
        case .invalidResponse:
            "Sunucudan okunabilir bir yanıt alınamadı."
        case let .requestFailed(statusCode, message):
            "Backend isteği başarısız oldu (\(statusCode)): \(message)"
        }
    }
}

private struct APIErrorResponse: Decodable {
    var error: String?
    var message: String?
}

struct APIClient {
    var supabaseURL = URL(string: "https://ifjghwsdpujzopppurdr.supabase.co")!
    var anonKey = "REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY"
    var accessToken: String?

    var functionsURL: URL {
        supabaseURL.appending(path: "functions/v1")
    }

    var isAuthenticated: Bool {
        accessToken?.isEmpty == false
    }

    func request(_ endpoint: APIEndpoint, method: String = "GET") -> URLRequest {
        var url = functionsURL.appending(path: endpoint.path)

        if case let .foodSearch(query) = endpoint {
            url.append(queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "region", value: "US"),
                URLQueryItem(name: "language", value: "en")
            ])
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func send<Body: Encodable, Response: Decodable>(
        _ endpoint: APIEndpoint,
        method: String = "POST",
        body: Body,
        responseType: Response.Type = Response.self
    ) async throws -> Response {
        if endpoint.requiresAuth && !isAuthenticated {
            throw APIError.missingAccessToken
        }

        var request = request(endpoint, method: method)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            let message = errorResponse?.error ?? errorResponse?.message ?? String(data: data, encoding: .utf8) ?? "unknown_error"
            throw APIError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}
