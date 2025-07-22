"""
Unit tests for the Copilot Plugin telemetry module
"""

import pytest
import os
from unittest.mock import Mock, patch, MagicMock
from src.telemetry import TelemetryManager, get_telemetry_manager, track_function


class TestTelemetryManager:
    """Test cases for TelemetryManager class"""
    
    def setup_method(self):
        """Setup test environment"""
        self.connection_string = "InstrumentationKey=test-key;IngestionEndpoint=https://test.in.applicationinsights.azure.com/"
    
    @patch('src.telemetry.TelemetryClient')
    @patch('src.telemetry.configure_azure_monitor')
    def test_telemetry_manager_initialization(self, mock_configure, mock_client):
        """Test TelemetryManager initialization with connection string"""
        manager = TelemetryManager(self.connection_string)
        
        assert manager.connection_string == self.connection_string
        assert manager.client is not None
        assert manager.logger is not None
        mock_configure.assert_called_once_with(connection_string=self.connection_string)
    
    def test_telemetry_manager_no_connection_string(self):
        """Test TelemetryManager initialization without connection string"""
        with patch.dict(os.environ, {}, clear=True):
            manager = TelemetryManager()
            assert manager.connection_string is None
            assert manager.client is None
    
    @patch('src.telemetry.TelemetryClient')
    def test_track_event(self, mock_client_class):
        """Test event tracking functionality"""
        mock_client = Mock()
        mock_client_class.return_value = mock_client
        
        manager = TelemetryManager(self.connection_string)
        
        event_name = "test_event"
        properties = {"key": "value"}
        measurements = {"duration": 123.45}
        
        manager.track_event(event_name, properties, measurements)
        
        mock_client.track_event.assert_called_once()
        call_args = mock_client.track_event.call_args
        
        assert call_args[0][0] == event_name
        assert "key" in call_args[0][1]
        assert call_args[0][2] == measurements
    
    @patch('src.telemetry.TelemetryClient')
    def test_track_request(self, mock_client_class):
        """Test request tracking functionality"""
        mock_client = Mock()
        mock_client_class.return_value = mock_client
        
        manager = TelemetryManager(self.connection_string)
        
        manager.track_request(
            name="test_request",
            url="https://test.com/api/test",
            success=True,
            duration_ms=150.0,
            response_code=200
        )
        
        mock_client.track_request.assert_called_once()
    
    @patch('src.telemetry.TelemetryClient')
    def test_track_exception(self, mock_client_class):
        """Test exception tracking functionality"""
        mock_client = Mock()
        mock_client_class.return_value = mock_client
        
        manager = TelemetryManager(self.connection_string)
        
        test_exception = ValueError("Test error")
        properties = {"context": "test"}
        
        manager.track_exception(test_exception, properties)
        
        mock_client.track_exception.assert_called_once()
    
    @patch('src.telemetry.TelemetryClient')
    def test_track_dependency(self, mock_client_class):
        """Test dependency tracking functionality"""
        mock_client = Mock()
        mock_client_class.return_value = mock_client
        
        manager = TelemetryManager(self.connection_string)
        
        manager.track_dependency(
            name="database_call",
            dependency_type="SQL",
            target="database.server.com",
            success=True,
            duration_ms=45.2
        )
        
        mock_client.track_dependency.assert_called_once()
    
    def test_correlation_context_creation(self):
        """Test correlation context creation"""
        manager = TelemetryManager()
        context = manager.create_correlation_context()
        
        assert "request_id" in context
        assert "timestamp" in context
        assert "plugin_version" in context
    
    def test_correlation_context_with_request_id(self):
        """Test correlation context with provided request ID"""
        manager = TelemetryManager()
        request_id = "test-request-id"
        context = manager.create_correlation_context(request_id)
        
        assert context["request_id"] == request_id


class TestTrackFunctionDecorator:
    """Test cases for track_function decorator"""
    
    @patch('src.telemetry.TelemetryManager')
    def test_successful_function_tracking(self, mock_manager_class):
        """Test decorator tracks successful function execution"""
        mock_manager = Mock()
        mock_manager_class.return_value = mock_manager
        mock_manager.start_operation.return_value = "mock_span"
        
        @track_function(mock_manager, "test_operation")
        def test_function(x, y):
            return x + y
        
        result = test_function(2, 3)
        
        assert result == 5
        mock_manager.start_operation.assert_called_once_with("test_operation")
        mock_manager.track_event.assert_called_once()
        mock_manager.end_operation.assert_called_once_with("mock_span", success=True)
    
    @patch('src.telemetry.TelemetryManager')
    def test_exception_function_tracking(self, mock_manager_class):
        """Test decorator tracks function exceptions"""
        mock_manager = Mock()
        mock_manager_class.return_value = mock_manager
        mock_manager.start_operation.return_value = "mock_span"
        
        @track_function(mock_manager, "test_operation")
        def failing_function():
            raise ValueError("Test error")
        
        with pytest.raises(ValueError):
            failing_function()
        
        mock_manager.track_exception.assert_called_once()
        mock_manager.track_event.assert_called_once()
        mock_manager.end_operation.assert_called_once_with(
            "mock_span", success=False, error_message="Test error"
        )


class TestGlobalTelemetryManager:
    """Test cases for global telemetry manager"""
    
    def test_get_telemetry_manager_singleton(self):
        """Test that get_telemetry_manager returns singleton instance"""
        with patch('src.telemetry._telemetry_instance', None):
            manager1 = get_telemetry_manager()
            manager2 = get_telemetry_manager()
            assert manager1 is manager2
    
    @patch('src.telemetry.TelemetryManager')
    def test_initialize_telemetry(self, mock_manager_class):
        """Test telemetry initialization with custom connection string"""
        from src.telemetry import initialize_telemetry
        
        connection_string = "test-connection-string"
        initialize_telemetry(connection_string)
        
        mock_manager_class.assert_called_once_with(connection_string)


if __name__ == "__main__":
    pytest.main([__file__])
