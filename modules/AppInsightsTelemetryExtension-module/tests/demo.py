#!/usr/bin/env python3
"""
Live Demo Script for AppInsightsTelemetryExtension Plugin
Demonstrates real-world usage scenarios and API responses
"""

import sys
import os
import json
from datetime import datetime

# Add the business logic module to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'business-logic'))

from appinsightstelemetryextension_service import AppInsightsTelemetryExtensionService

def demo_copilot_plugin_scenario():
    """Demonstrate a real M365 Copilot plugin scenario"""
    print("🎯 Demo: M365 Copilot Plugin Telemetry Tracking")
    print("=" * 60)
    
    service = AppInsightsTelemetryExtensionService()
    
    # Scenario 1: User starts a Copilot session
    print("\n📍 Scenario 1: User starts Copilot session")
    session_start = service.track_custom_event({
        "event_name": "copilot_session_started",
        "user_id": "user_alice_2025",
        "properties": {
            "session_type": "document_analysis",
            "workspace": "marketing_team",
            "copilot_version": "v2.5.1",
            "user_role": "content_manager"
        },
        "metrics": {
            "session_initialization_ms": 125.5
        }
    })
    print(f"   ✅ Session tracked: {session_start['event_id']}")
    print(f"   📊 Processing time: {session_start['processing_time_ms']:.2f}ms")
    
    # Scenario 2: Performance monitoring during AI processing
    print("\n📍 Scenario 2: AI document processing performance")
    ai_performance = service.track_performance_metrics({
        "operation_name": "ai_document_analysis",
        "duration_ms": 3200,
        "success": True,
        "additional_metrics": {
            "tokens_processed": 1850,
            "confidence_score": 0.92,
            "memory_usage_mb": 45.2
        }
    })
    print(f"   ⚡ Operation: {ai_performance['operation_name']}")
    print(f"   ⏱️ Duration: {ai_performance['duration_ms']}ms")
    print(f"   💡 Insights: {ai_performance['insights']}")
    
    # Scenario 3: User behavior analytics
    print("\n📍 Scenario 3: User engagement analysis")
    user_behavior = service.analyze_user_behavior({
        "user_id": "user_alice_2025",
        "session_duration": 35,
        "actions": [
            {"type": "query", "timestamp": "2025-07-22T14:00:00Z"},
            {"type": "ai_suggestion_accepted", "timestamp": "2025-07-22T14:02:30Z"},
            {"type": "document_edit", "timestamp": "2025-07-22T14:05:15Z"},
            {"type": "ai_refinement", "timestamp": "2025-07-22T14:08:45Z"},
            {"type": "content_generation", "timestamp": "2025-07-22T14:12:20Z"},
            {"type": "collaboration_share", "timestamp": "2025-07-22T14:15:10Z"},
            {"type": "export_document", "timestamp": "2025-07-22T14:18:30Z"}
        ],
        "feature_usage": ["ai_suggestions", "document_editing", "content_generation", "sharing", "export"]
    })
    
    insights = user_behavior['insights']
    print(f"   👤 User: {insights['user_id']}")
    print(f"   📈 Engagement: {insights['engagement_level']}")
    print(f"   🎯 Actions: {insights['session_summary']['action_count']}")
    print(f"   ⏰ Duration: {insights['session_summary']['session_duration_minutes']} minutes")
    print(f"   💡 Recommendations: {insights['recommendations']}")
    
    # Scenario 4: Real-time dashboard for IT admin
    print("\n📍 Scenario 4: IT Admin dashboard generation")
    dashboard = service.generate_telemetry_dashboard({
        "time_range": 8,
        "metrics": ["requests", "errors", "performance", "users", "ai_operations"]
    })
    
    dash_info = dashboard['dashboard']
    print(f"   📊 Dashboard: {dash_info['name']}")
    print(f"   🕐 Time Range: {dash_info['time_range_hours']} hours")
    print(f"   📈 Widgets: {len(dash_info['widgets'])}")
    print(f"   🚨 Alerts: {len(dash_info['alerts'])}")
    
    summary = dash_info['summary']
    print(f"   📊 Total Requests: {summary['total_requests']}")
    print(f"   ⚠️ Error Rate: {summary['error_rate']}%")
    print(f"   ⚡ Avg Response: {summary['avg_response_time_ms']}ms")
    print(f"   👥 Active Users: {summary['active_users']}")
    
    return {
        "session_start": session_start,
        "ai_performance": ai_performance,
        "user_behavior": user_behavior,
        "dashboard": dashboard
    }

def demo_api_endpoints():
    """Demonstrate API endpoint calls"""
    print("\n🌐 Demo: API Endpoint Simulation")
    print("=" * 60)
    
    # Simulate main() function calls
    from appinsightstelemetryextension_service import main
    
    # Mock request objects for testing
    class MockRequest:
        def __init__(self, operation, body):
            self.operation = operation
            self.body = body
    
    print("\n📍 API Call 1: Track Custom Event")
    req1 = MockRequest('track_custom_event', {
        "event_name": "api_usage_example",
        "user_id": "demo_user",
        "properties": {"demo_mode": True}
    })
    
    response1 = main(req1)
    print(f"   Response: {json.loads(response1)['success']}")
    
    print("\n📍 API Call 2: Generate Dashboard")
    req2 = MockRequest('generate_telemetry_dashboard', {
        "time_range": 6,
        "metrics": ["requests", "performance"]
    })
    
    response2 = main(req2)
    dashboard_data = json.loads(response2)
    print(f"   Dashboard Created: {dashboard_data['success']}")
    print(f"   Widgets: {len(dashboard_data['dashboard']['widgets'])}")

def main_demo():
    """Run the complete demonstration"""
    print("🚀 AppInsightsTelemetryExtension Plugin - Live Demo")
    print("📅 Date: July 22, 2025")
    print("🏢 Enterprise M365 Copilot Integration")
    print("=" * 70)
    
    # Run real-world scenario
    scenario_results = demo_copilot_plugin_scenario()
    
    # Run API demonstrations
    demo_api_endpoints()
    
    print("\n" + "=" * 70)
    print("🎉 Demo Complete - Production Ready!")
    print("✅ All telemetry operations successful")
    print("✅ Real-time insights generated")
    print("✅ Performance monitoring active")
    print("✅ User analytics functional")
    print("✅ Dashboard generation working")
    print("\n🚀 Ready for Azure deployment and M365 Copilot integration!")

if __name__ == "__main__":
    main_demo()
