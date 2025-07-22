#!/usr/bin/env python3
"""
Test script for AppInsightsTelemetryExtension plugin
Validates core functionality without requiring Azure Functions runtime
"""

import sys
import os
import json
from datetime import datetime

# Add the business logic module to path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'business-logic'))

try:
    from appinsightstelemetryextension_service import AppInsightsTelemetryExtensionService, TelemetryEvent
    print("✅ Successfully imported AppInsightsTelemetryExtension service")
except ImportError as e:
    print(f"❌ Import error: {e}")
    sys.exit(1)

def test_telemetry_event():
    """Test TelemetryEvent dataclass"""
    print("\n🧪 Testing TelemetryEvent creation...")
    
    event = TelemetryEvent(
        event_name="test_event",
        event_type="unit_test",
        user_id="test_user_123",
        properties={"test_property": "test_value"},
        metrics={"test_metric": 123.45}
    )
    
    print(f"   Event Name: {event.event_name}")
    print(f"   Event Type: {event.event_type}")
    print(f"   User ID: {event.user_id}")
    print(f"   Properties: {event.properties}")
    print(f"   Metrics: {event.metrics}")
    print(f"   Timestamp: {event.timestamp}")
    print("✅ TelemetryEvent test passed")

def test_service_initialization():
    """Test service initialization"""
    print("\n🧪 Testing service initialization...")
    
    service = AppInsightsTelemetryExtensionService()
    
    print(f"   Session ID: {service.session_id}")
    print(f"   Azure Available: {service.azure_available}")
    print("✅ Service initialization test passed")

def test_track_custom_event():
    """Test custom event tracking"""
    print("\n🧪 Testing custom event tracking...")
    
    service = AppInsightsTelemetryExtensionService()
    
    test_event_data = {
        "event_name": "plugin_test_event",
        "user_id": "test_user_456",
        "properties": {
            "test_environment": "unit_testing",
            "plugin_version": "1.0.0",
            "operation_type": "validation"
        },
        "metrics": {
            "test_duration_ms": 150.25,
            "test_score": 0.95
        }
    }
    
    result = service.track_custom_event(test_event_data)
    
    print(f"   Success: {result['success']}")
    print(f"   Event ID: {result.get('event_id', 'N/A')}")
    print(f"   Event Name: {result.get('event_name', 'N/A')}")
    print(f"   Processing Time: {result.get('processing_time_ms', 'N/A')}ms")
    print(f"   Properties Count: {result.get('properties_count', 'N/A')}")
    print(f"   Metrics Count: {result.get('metrics_count', 'N/A')}")
    
    assert result['success'] == True, "Custom event tracking should succeed"
    print("✅ Custom event tracking test passed")

def test_track_performance_metrics():
    """Test performance metrics tracking"""
    print("\n🧪 Testing performance metrics tracking...")
    
    service = AppInsightsTelemetryExtensionService()
    
    test_metrics_data = {
        "operation_name": "test_operation",
        "duration_ms": 1200,
        "success": True,
        "additional_metrics": {
            "memory_usage_mb": 32.5,
            "cpu_percentage": 15.8
        }
    }
    
    result = service.track_performance_metrics(test_metrics_data)
    
    print(f"   Success: {result['success']}")
    print(f"   Metrics ID: {result.get('metrics_id', 'N/A')}")
    print(f"   Operation Name: {result.get('operation_name', 'N/A')}")
    print(f"   Duration: {result.get('duration_ms', 'N/A')}ms")
    print(f"   Insights: {result.get('insights', [])}")
    
    assert result['success'] == True, "Performance metrics tracking should succeed"
    print("✅ Performance metrics tracking test passed")

def test_analyze_user_behavior():
    """Test user behavior analysis"""
    print("\n🧪 Testing user behavior analysis...")
    
    service = AppInsightsTelemetryExtensionService()
    
    test_behavior_data = {
        "user_id": "test_user_789",
        "session_duration": 25,
        "actions": [
            {"type": "login", "timestamp": "2025-01-22T08:00:00Z"},
            {"type": "search", "timestamp": "2025-01-22T08:05:00Z"},
            {"type": "view_document", "timestamp": "2025-01-22T08:10:00Z"},
            {"type": "edit", "timestamp": "2025-01-22T08:15:00Z"},
            {"type": "save", "timestamp": "2025-01-22T08:20:00Z"},
            {"type": "share", "timestamp": "2025-01-22T08:25:00Z"}
        ],
        "feature_usage": ["search", "edit", "save", "share", "export"]
    }
    
    result = service.analyze_user_behavior(test_behavior_data)
    
    print(f"   Success: {result['success']}")
    print(f"   Analysis ID: {result.get('analysis_id', 'N/A')}")
    print(f"   User ID: {result.get('user_id', 'N/A')}")
    
    insights = result.get('insights', {})
    session_summary = insights.get('session_summary', {})
    print(f"   Action Count: {session_summary.get('action_count', 'N/A')}")
    print(f"   Session Duration: {session_summary.get('session_duration_minutes', 'N/A')} minutes")
    print(f"   Engagement Level: {insights.get('engagement_level', 'N/A')}")
    print(f"   Recommendations: {insights.get('recommendations', [])}")
    
    assert result['success'] == True, "User behavior analysis should succeed"
    print("✅ User behavior analysis test passed")

def test_generate_telemetry_dashboard():
    """Test telemetry dashboard generation"""
    print("\n🧪 Testing telemetry dashboard generation...")
    
    service = AppInsightsTelemetryExtensionService()
    
    test_dashboard_config = {
        "time_range": 12,
        "metrics": ["requests", "errors", "performance", "users"]
    }
    
    result = service.generate_telemetry_dashboard(test_dashboard_config)
    
    print(f"   Success: {result['success']}")
    
    dashboard = result.get('dashboard', {})
    print(f"   Dashboard ID: {dashboard.get('dashboard_id', 'N/A')}")
    print(f"   Dashboard Name: {dashboard.get('name', 'N/A')}")
    print(f"   Time Range: {dashboard.get('time_range_hours', 'N/A')} hours")
    print(f"   Widget Count: {len(dashboard.get('widgets', []))}")
    print(f"   Alert Count: {len(dashboard.get('alerts', []))}")
    
    summary = dashboard.get('summary', {})
    print(f"   Total Requests: {summary.get('total_requests', 'N/A')}")
    print(f"   Error Rate: {summary.get('error_rate', 'N/A')}%")
    print(f"   Avg Response Time: {summary.get('avg_response_time_ms', 'N/A')}ms")
    print(f"   Active Users: {summary.get('active_users', 'N/A')}")
    
    assert result['success'] == True, "Dashboard generation should succeed"
    print("✅ Telemetry dashboard generation test passed")

def main():
    """Run all tests"""
    print("🚀 Starting AppInsightsTelemetryExtension Plugin Tests")
    print("=" * 60)
    
    try:
        test_telemetry_event()
        test_service_initialization()
        test_track_custom_event()
        test_track_performance_metrics()
        test_analyze_user_behavior()
        test_generate_telemetry_dashboard()
        
        print("\n" + "=" * 60)
        print("🎉 All tests passed successfully!")
        print("✅ AppInsightsTelemetryExtension plugin is ready for deployment")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
