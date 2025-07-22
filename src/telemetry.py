"""
Telemetry module for Microsoft 365 Copilot Plugin
Implements Application Insights integration with best practices for Azure monitoring
"""

import logging
import os
import time
import uuid
from datetime import datetime
from typing import Any, Dict, Optional, Union
from functools import wraps

try:
    from applicationinsights import TelemetryClient
    from applicationinsights.logging import LoggingHandler
    from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
    from azure.monitor.opentelemetry import configure_azure_monitor
    import opentelemetry
    from opentelemetry import trace
    from opentelemetry.trace import Status, StatusCode
except ImportError as e:
    print(f"Missing required packages: {e}")
    print("Install with: pip install applicationinsights azure-identity azure-monitor-opentelemetry")
    raise

class TelemetryManager:
    """
    Centralized telemetry management for the Copilot plugin
    Implements Azure Application Insights integration with proper error handling
    """
    
    def __init__(self, connection_string: Optional[str] = None):
        """
        Initialize telemetry manager with Application Insights
        
        Args:
            connection_string: Application Insights connection string
                              If not provided, will attempt to get from environment
        """
        self.connection_string = connection_string or os.getenv('APPLICATION_INSIGHTS_CONNECTION_STRING')
        self.client: Optional[TelemetryClient] = None
        self.tracer = None
        self.logger = self._setup_logger()
        
        if self.connection_string:
            self._initialize_telemetry()
        else:
            self.logger.warning("Application Insights connection string not found. Telemetry disabled.")
    
    def _setup_logger(self) -> logging.Logger:
        """Setup structured logging with appropriate formatting"""
        logger = logging.getLogger('copilot_plugin')
        logger.setLevel(logging.INFO)
        
        if not logger.handlers:
            # Console handler for local development
            console_handler = logging.StreamHandler()
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            console_handler.setFormatter(formatter)
            logger.addHandler(console_handler)
        
        return logger
    
    def _initialize_telemetry(self):
        """Initialize Application Insights telemetry client and OpenTelemetry"""
        try:
            # Initialize Application Insights client
            self.client = TelemetryClient(instrumentation_key=self._extract_instrumentation_key())
            
            # Configure Azure Monitor for OpenTelemetry
            configure_azure_monitor(connection_string=self.connection_string)
            
            # Get tracer for distributed tracing
            self.tracer = trace.get_tracer(__name__)
            
            # Add Application Insights handler to logger
            if self.client:
                ai_handler = LoggingHandler(self.connection_string)
                ai_handler.setLevel(logging.INFO)
                self.logger.addHandler(ai_handler)
            
            self.logger.info("Telemetry initialized successfully")
            
        except Exception as e:
            self.logger.error(f"Failed to initialize telemetry: {e}")
            # Don't fail the application if telemetry setup fails
            self.client = None
            self.tracer = None
    
    def _extract_instrumentation_key(self) -> Optional[str]:
        """Extract instrumentation key from connection string for backwards compatibility"""
        if not self.connection_string:
            return None
        
        try:
            parts = self.connection_string.split(';')
            for part in parts:
                if part.startswith('InstrumentationKey='):
                    return part.split('=', 1)[1]
        except Exception:
            pass
        return None
    
    def track_event(self, name: str, properties: Optional[Dict[str, Any]] = None, 
                   measurements: Optional[Dict[str, Union[int, float]]] = None):
        """
        Track custom events
        
        Args:
            name: Event name
            properties: Custom properties as key-value pairs
            measurements: Numeric measurements
        """
        if not self.client:
            self.logger.info(f"Event: {name}, Properties: {properties}, Measurements: {measurements}")
            return
        
        try:
            # Add default properties
            default_properties = {
                'timestamp': datetime.utcnow().isoformat(),
                'plugin_version': '1.0.0',
                'environment': os.getenv('ENVIRONMENT', 'development')
            }
            
            if properties:
                default_properties.update(properties)
            
            self.client.track_event(name, default_properties, measurements)
            self.client.flush()
            
        except Exception as e:
            self.logger.error(f"Failed to track event {name}: {e}")
    
    def track_request(self, name: str, url: str, success: bool, 
                     duration_ms: float, response_code: int = 200,
                     properties: Optional[Dict[str, Any]] = None):
        """
        Track HTTP requests
        
        Args:
            name: Request name
            url: Request URL
            success: Whether request was successful
            duration_ms: Request duration in milliseconds
            response_code: HTTP response code
            properties: Additional properties
        """
        if not self.client:
            self.logger.info(f"Request: {name}, URL: {url}, Success: {success}, Duration: {duration_ms}ms")
            return
        
        try:
            request_id = str(uuid.uuid4())
            default_properties = {
                'request_id': request_id,
                'user_agent': 'Microsoft365Copilot/1.0',
                'environment': os.getenv('ENVIRONMENT', 'development')
            }
            
            if properties:
                default_properties.update(properties)
            
            self.client.track_request(
                name=name,
                url=url,
                success=success,
                duration=duration_ms,
                response_code=response_code,
                properties=default_properties
            )
            self.client.flush()
            
        except Exception as e:
            self.logger.error(f"Failed to track request {name}: {e}")
    
    def track_exception(self, exception: Exception, 
                       properties: Optional[Dict[str, Any]] = None):
        """
        Track exceptions with context
        
        Args:
            exception: Exception to track
            properties: Additional context properties
        """
        if not self.client:
            self.logger.exception(f"Exception: {exception}")
            return
        
        try:
            default_properties = {
                'timestamp': datetime.utcnow().isoformat(),
                'exception_type': type(exception).__name__,
                'environment': os.getenv('ENVIRONMENT', 'development')
            }
            
            if properties:
                default_properties.update(properties)
            
            self.client.track_exception(exception, properties=default_properties)
            self.client.flush()
            
        except Exception as e:
            self.logger.error(f"Failed to track exception: {e}")
    
    def track_dependency(self, name: str, dependency_type: str, target: str,
                        success: bool, duration_ms: float,
                        properties: Optional[Dict[str, Any]] = None):
        """
        Track external dependencies (APIs, databases, etc.)
        
        Args:
            name: Dependency name
            dependency_type: Type of dependency (HTTP, SQL, etc.)
            target: Target endpoint or resource
            success: Whether dependency call was successful
            duration_ms: Call duration in milliseconds
            properties: Additional properties
        """
        if not self.client:
            self.logger.info(f"Dependency: {name}, Type: {dependency_type}, Success: {success}")
            return
        
        try:
            default_properties = {
                'timestamp': datetime.utcnow().isoformat(),
                'environment': os.getenv('ENVIRONMENT', 'development')
            }
            
            if properties:
                default_properties.update(properties)
            
            self.client.track_dependency(
                name=name,
                dependency_type=dependency_type,
                target=target,
                success=success,
                duration=duration_ms,
                properties=default_properties
            )
            self.client.flush()
            
        except Exception as e:
            self.logger.error(f"Failed to track dependency {name}: {e}")
    
    def start_operation(self, operation_name: str) -> Optional[Any]:
        """
        Start a distributed tracing operation
        
        Args:
            operation_name: Name of the operation
            
        Returns:
            Span context for the operation
        """
        if not self.tracer:
            return None
        
        try:
            span = self.tracer.start_span(operation_name)
            span.set_attribute("operation.name", operation_name)
            span.set_attribute("plugin.version", "1.0.0")
            return span
        except Exception as e:
            self.logger.error(f"Failed to start operation {operation_name}: {e}")
            return None
    
    def end_operation(self, span: Any, success: bool = True, 
                     error_message: Optional[str] = None):
        """
        End a distributed tracing operation
        
        Args:
            span: Span context from start_operation
            success: Whether operation was successful
            error_message: Error message if operation failed
        """
        if not span:
            return
        
        try:
            if success:
                span.set_status(Status(StatusCode.OK))
            else:
                span.set_status(Status(StatusCode.ERROR, error_message or "Operation failed"))
                if error_message:
                    span.set_attribute("error.message", error_message)
            
            span.end()
        except Exception as e:
            self.logger.error(f"Failed to end operation: {e}")
    
    def create_correlation_context(self, request_id: Optional[str] = None) -> Dict[str, str]:
        """
        Create correlation context for request tracking
        
        Args:
            request_id: Optional request ID, will generate if not provided
            
        Returns:
            Correlation context dictionary
        """
        return {
            'request_id': request_id or str(uuid.uuid4()),
            'timestamp': datetime.utcnow().isoformat(),
            'plugin_version': '1.0.0'
        }

# Decorator for automatic telemetry tracking
def track_function(telemetry_manager: TelemetryManager, operation_name: Optional[str] = None):
    """
    Decorator to automatically track function execution
    
    Args:
        telemetry_manager: Instance of TelemetryManager
        operation_name: Optional custom operation name
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            op_name = operation_name or f"{func.__module__}.{func.__name__}"
            start_time = time.time()
            span = telemetry_manager.start_operation(op_name)
            
            try:
                result = func(*args, **kwargs)
                duration_ms = (time.time() - start_time) * 1000
                
                telemetry_manager.track_event(
                    f"function_executed",
                    properties={
                        'function_name': func.__name__,
                        'module': func.__module__,
                        'success': True
                    },
                    measurements={'duration_ms': duration_ms}
                )
                
                telemetry_manager.end_operation(span, success=True)
                return result
                
            except Exception as e:
                duration_ms = (time.time() - start_time) * 1000
                
                telemetry_manager.track_exception(
                    e,
                    properties={
                        'function_name': func.__name__,
                        'module': func.__module__
                    }
                )
                
                telemetry_manager.track_event(
                    f"function_error",
                    properties={
                        'function_name': func.__name__,
                        'module': func.__module__,
                        'error_type': type(e).__name__,
                        'error_message': str(e)
                    },
                    measurements={'duration_ms': duration_ms}
                )
                
                telemetry_manager.end_operation(span, success=False, error_message=str(e))
                raise
        
        return wrapper
    return decorator

# Global telemetry instance
_telemetry_instance: Optional[TelemetryManager] = None

def get_telemetry_manager() -> TelemetryManager:
    """Get or create global telemetry manager instance"""
    global _telemetry_instance
    if _telemetry_instance is None:
        _telemetry_instance = TelemetryManager()
    return _telemetry_instance

def initialize_telemetry(connection_string: Optional[str] = None) -> TelemetryManager:
    """Initialize telemetry with custom connection string"""
    global _telemetry_instance
    _telemetry_instance = TelemetryManager(connection_string)
    return _telemetry_instance
