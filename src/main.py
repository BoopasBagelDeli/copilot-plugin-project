"""
Main Azure Functions application for Microsoft 365 Copilot Plugin
Implements declarative plugin endpoints with telemetry and security best practices
"""

import json
import logging
import os
import time
from datetime import datetime
from typing import Any, Dict, List, Optional, Union

import azure.functions as func
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient

# Import telemetry module
from .telemetry import get_telemetry_manager, track_function

# Initialize the Azure Functions app
app = func.FunctionApp()

# Global telemetry manager
telemetry = get_telemetry_manager()

# Configuration
class Config:
    """Application configuration with Azure best practices"""
    
    def __init__(self):
        self.environment = os.getenv('ENVIRONMENT', 'development')
        self.debug = self.environment == 'development'
        
        # Azure Key Vault configuration
        self.key_vault_url = os.getenv('KEY_VAULT_URL')
        self.secret_client = None
        
        # Authentication
        self.tenant_id = os.getenv('AZURE_TENANT_ID')
        self.client_id = os.getenv('AZURE_CLIENT_ID')
        
        # Rate limiting
        self.rate_limit_per_minute = int(os.getenv('RATE_LIMIT_PER_MINUTE', '100'))
        self.burst_limit = int(os.getenv('BURST_LIMIT', '20'))
        
        # Initialize Key Vault client with managed identity
        self._initialize_key_vault()
    
    def _initialize_key_vault(self):
        """Initialize Key Vault client using managed identity"""
        if not self.key_vault_url:
            telemetry.logger.warning("Key Vault URL not configured")
            return
        
        try:
            # Use managed identity in Azure, default credential locally
            credential = DefaultAzureCredential()
            self.secret_client = SecretClient(
                vault_url=self.key_vault_url,
                credential=credential
            )
            telemetry.logger.info("Key Vault client initialized successfully")
        except Exception as e:
            telemetry.track_exception(e, {'component': 'key_vault_init'})
            telemetry.logger.error(f"Failed to initialize Key Vault client: {e}")
    
    def get_secret(self, secret_name: str) -> Optional[str]:
        """Retrieve secret from Key Vault with caching"""
        if not self.secret_client:
            return os.getenv(secret_name.upper())
        
        try:
            secret = self.secret_client.get_secret(secret_name)
            return secret.value
        except Exception as e:
            telemetry.track_exception(e, {
                'component': 'key_vault_get_secret',
                'secret_name': secret_name
            })
            # Fallback to environment variable
            return os.getenv(secret_name.upper())

# Global configuration
config = Config()

# Request validation and security
class SecurityMiddleware:
    """Security middleware for request validation and authentication"""
    
    @staticmethod
    def validate_bearer_token(req: func.HttpRequest) -> Dict[str, Any]:
        """
        Validate Bearer token from Authorization header
        In production, this should validate against Azure AD
        """
        auth_header = req.headers.get('Authorization', '')
        
        if not auth_header.startswith('Bearer '):
            raise ValueError("Missing or invalid Authorization header")
        
        token = auth_header[7:]  # Remove 'Bearer ' prefix
        
        # TODO: Implement proper JWT validation with Azure AD
        # For now, just check if token exists
        if not token:
            raise ValueError("Empty bearer token")
        
        # Return mock user context - replace with actual token validation
        return {
            'user_id': 'mock_user',
            'tenant_id': config.tenant_id,
            'scopes': ['api://your-app-id/access_as_user']
        }
    
    @staticmethod
    def validate_request_size(req: func.HttpRequest, max_size: int = 10 * 1024 * 1024):
        """Validate request body size"""
        content_length = req.headers.get('Content-Length')
        if content_length and int(content_length) > max_size:
            raise ValueError(f"Request body too large. Maximum size: {max_size} bytes")
    
    @staticmethod
    def sanitize_input(data: str, max_length: int = 10000) -> str:
        """Basic input sanitization"""
        if len(data) > max_length:
            raise ValueError(f"Input too long. Maximum length: {max_length}")
        
        # Remove potentially dangerous characters
        sanitized = data.replace('<', '&lt;').replace('>', '&gt;')
        return sanitized.strip()

# Business logic services
class SearchService:
    """Service for handling search operations"""
    
    @staticmethod
    @track_function(telemetry, "search_data")
    def search_data(query: str, limit: int = 10, category: Optional[str] = None) -> Dict[str, Any]:
        """
        Search for data based on query
        In production, this would integrate with actual data sources
        """
        start_time = time.time()
        
        try:
            # Simulate search operation
            results = []
            
            # Mock search results based on category
            categories = ['documents', 'contacts', 'events', 'tasks'] if not category else [category]
            
            for i, cat in enumerate(categories[:limit]):
                result = {
                    'id': f"{cat}_{i+1}",
                    'title': f"Sample {cat.title()} Result {i+1}",
                    'summary': f"This is a sample {cat} result for query: {query}",
                    'url': f"https://company.com/{cat}/{i+1}",
                    'category': cat,
                    'relevance': max(0.9 - (i * 0.1), 0.1),
                    'metadata': {
                        'created_date': datetime.utcnow().isoformat(),
                        'source': f"{cat}_system"
                    }
                }
                results.append(result)
            
            # Track search metrics
            duration_ms = (time.time() - start_time) * 1000
            telemetry.track_event(
                'search_completed',
                properties={
                    'query_length': len(query),
                    'category': category or 'all',
                    'result_count': len(results)
                },
                measurements={'duration_ms': duration_ms}
            )
            
            return {
                'results': results,
                'total': len(results),
                'query': query,
                'facets': {
                    'categories': categories,
                    'sources': [f"{cat}_system" for cat in categories]
                }
            }
            
        except Exception as e:
            telemetry.track_exception(e, {
                'operation': 'search_data',
                'query': query,
                'category': category
            })
            raise

class AnalysisService:
    """Service for content analysis operations"""
    
    @staticmethod
    @track_function(telemetry, "analyze_content")
    def analyze_content(content: str, analysis_type: str, options: Optional[Dict] = None) -> Dict[str, Any]:
        """
        Analyze content based on type
        In production, this would use actual ML/AI services
        """
        start_time = time.time()
        
        try:
            options = options or {}
            language = options.get('language', 'en-US')
            include_confidence = options.get('includeConfidence', False)
            
            # Mock analysis results based on type
            if analysis_type == 'sentiment':
                result = {
                    'sentiment': 'positive',
                    'score': 0.85,
                    'aspects': ['quality', 'service', 'value']
                }
            elif analysis_type == 'keywords':
                result = {
                    'keywords': ['important', 'analysis', 'content', 'insights'],
                    'phrases': ['key phrase 1', 'important concept']
                }
            elif analysis_type == 'summary':
                result = {
                    'summary': f"This content discusses important topics and provides valuable insights. (Original length: {len(content)} characters)",
                    'key_points': ['Point 1', 'Point 2', 'Point 3']
                }
            elif analysis_type == 'insights':
                result = {
                    'insights': ['The content shows positive sentiment', 'Key themes identified'],
                    'recommendations': ['Consider expanding on key points', 'Add more specific examples']
                }
            else:
                raise ValueError(f"Unsupported analysis type: {analysis_type}")
            
            # Add confidence scores if requested
            confidence = 0.87 if include_confidence else None
            
            # Track analysis metrics
            duration_ms = (time.time() - start_time) * 1000
            telemetry.track_event(
                'analysis_completed',
                properties={
                    'analysis_type': analysis_type,
                    'content_length': len(content),
                    'language': language
                },
                measurements={'duration_ms': duration_ms}
            )
            
            response = {
                'analysisType': analysis_type,
                'result': result,
                'processing_time': duration_ms / 1000
            }
            
            if confidence is not None:
                response['confidence'] = confidence
            
            return response
            
        except Exception as e:
            telemetry.track_exception(e, {
                'operation': 'analyze_content',
                'analysis_type': analysis_type,
                'content_length': len(content)
            })
            raise

# Azure Functions endpoints
@app.route(route="search", auth_level=func.AuthLevel.FUNCTION, methods=["GET"])
@track_function(telemetry, "api_search")
def search_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    """Search endpoint for the Copilot plugin"""
    
    correlation_context = telemetry.create_correlation_context()
    
    try:
        # Security validation
        user_context = SecurityMiddleware.validate_bearer_token(req)
        
        # Extract and validate parameters
        query = req.params.get('query')
        if not query:
            raise ValueError("Query parameter is required")
        
        # Sanitize input
        query = SecurityMiddleware.sanitize_input(query, max_length=500)
        
        limit = min(int(req.params.get('limit', '10')), 100)
        category = req.params.get('category')
        
        if category and category not in ['documents', 'contacts', 'events', 'tasks']:
            raise ValueError("Invalid category. Must be one of: documents, contacts, events, tasks")
        
        # Track request
        start_time = time.time()
        
        # Perform search
        search_results = SearchService.search_data(query, limit, category)
        
        # Track successful request
        duration_ms = (time.time() - start_time) * 1000
        telemetry.track_request(
            name="search",
            url=req.url,
            success=True,
            duration_ms=duration_ms,
            response_code=200,
            properties={
                **correlation_context,
                'user_id': user_context.get('user_id'),
                'query_length': len(query),
                'result_count': len(search_results['results'])
            }
        )
        
        return func.HttpResponse(
            json.dumps(search_results, default=str),
            status_code=200,
            headers={
                'Content-Type': 'application/json',
                'X-Request-ID': correlation_context['request_id']
            }
        )
        
    except ValueError as e:
        error_response = {
            'error': 'validation_error',
            'message': str(e),
            'timestamp': datetime.utcnow().isoformat(),
            'request_id': correlation_context['request_id']
        }
        
        telemetry.track_request(
            name="search",
            url=req.url,
            success=False,
            duration_ms=(time.time() - start_time) * 1000 if 'start_time' in locals() else 0,
            response_code=400,
            properties={**correlation_context, 'error': str(e)}
        )
        
        return func.HttpResponse(
            json.dumps(error_response),
            status_code=400,
            headers={'Content-Type': 'application/json'}
        )
        
    except Exception as e:
        telemetry.track_exception(e, {
            **correlation_context,
            'endpoint': 'search'
        })
        
        error_response = {
            'error': 'internal_error',
            'message': 'An internal error occurred',
            'timestamp': datetime.utcnow().isoformat(),
            'request_id': correlation_context['request_id']
        }
        
        return func.HttpResponse(
            json.dumps(error_response),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )

@app.route(route="analyze", auth_level=func.AuthLevel.FUNCTION, methods=["POST"])
@track_function(telemetry, "api_analyze")
def analyze_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    """Content analysis endpoint for the Copilot plugin"""
    
    correlation_context = telemetry.create_correlation_context()
    
    try:
        # Security validation
        user_context = SecurityMiddleware.validate_bearer_token(req)
        SecurityMiddleware.validate_request_size(req)
        
        # Parse request body
        try:
            request_data = req.get_json()
        except ValueError:
            raise ValueError("Invalid JSON in request body")
        
        if not request_data:
            raise ValueError("Request body is required")
        
        # Extract and validate parameters
        content = request_data.get('content')
        if not content:
            raise ValueError("Content field is required")
        
        analysis_type = request_data.get('analysisType')
        if not analysis_type or analysis_type not in ['sentiment', 'keywords', 'summary', 'insights']:
            raise ValueError("Invalid analysisType. Must be one of: sentiment, keywords, summary, insights")
        
        # Sanitize content
        content = SecurityMiddleware.sanitize_input(content)
        
        options = request_data.get('options', {})
        
        # Track request
        start_time = time.time()
        
        # Perform analysis
        analysis_results = AnalysisService.analyze_content(content, analysis_type, options)
        
        # Track successful request
        duration_ms = (time.time() - start_time) * 1000
        telemetry.track_request(
            name="analyze",
            url=req.url,
            success=True,
            duration_ms=duration_ms,
            response_code=200,
            properties={
                **correlation_context,
                'user_id': user_context.get('user_id'),
                'analysis_type': analysis_type,
                'content_length': len(content)
            }
        )
        
        return func.HttpResponse(
            json.dumps(analysis_results, default=str),
            status_code=200,
            headers={
                'Content-Type': 'application/json',
                'X-Request-ID': correlation_context['request_id']
            }
        )
        
    except ValueError as e:
        error_response = {
            'error': 'validation_error',
            'message': str(e),
            'timestamp': datetime.utcnow().isoformat(),
            'request_id': correlation_context['request_id']
        }
        
        telemetry.track_request(
            name="analyze",
            url=req.url,
            success=False,
            duration_ms=(time.time() - start_time) * 1000 if 'start_time' in locals() else 0,
            response_code=400,
            properties={**correlation_context, 'error': str(e)}
        )
        
        return func.HttpResponse(
            json.dumps(error_response),
            status_code=400,
            headers={'Content-Type': 'application/json'}
        )
        
    except Exception as e:
        telemetry.track_exception(e, {
            **correlation_context,
            'endpoint': 'analyze'
        })
        
        error_response = {
            'error': 'internal_error',
            'message': 'An internal error occurred',
            'timestamp': datetime.utcnow().isoformat(),
            'request_id': correlation_context['request_id']
        }
        
        return func.HttpResponse(
            json.dumps(error_response),
            status_code=500,
            headers={'Content-Type': 'application/json'}
        )

@app.route(route="health", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])
@track_function(telemetry, "api_health")
def health_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    """Health check endpoint"""
    
    correlation_context = telemetry.create_correlation_context()
    
    try:
        # Check application health
        health_status = {
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0',
            'dependencies': {
                'telemetry': 'up' if telemetry.client else 'down',
                'key_vault': 'up' if config.secret_client else 'unknown'
            }
        }
        
        # Determine overall health
        if health_status['dependencies']['telemetry'] == 'down':
            health_status['status'] = 'degraded'
        
        status_code = 200 if health_status['status'] in ['healthy', 'degraded'] else 503
        
        # Track health check
        telemetry.track_request(
            name="health",
            url=req.url,
            success=status_code == 200,
            duration_ms=0,  # Health checks should be fast
            response_code=status_code,
            properties=correlation_context
        )
        
        return func.HttpResponse(
            json.dumps(health_status, default=str),
            status_code=status_code,
            headers={
                'Content-Type': 'application/json',
                'X-Request-ID': correlation_context['request_id']
            }
        )
        
    except Exception as e:
        telemetry.track_exception(e, {
            **correlation_context,
            'endpoint': 'health'
        })
        
        error_response = {
            'status': 'unhealthy',
            'timestamp': datetime.utcnow().isoformat(),
            'error': str(e),
            'request_id': correlation_context['request_id']
        }
        
        return func.HttpResponse(
            json.dumps(error_response),
            status_code=503,
            headers={'Content-Type': 'application/json'}
        )

@app.route(route="openapi", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])
def openapi_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    """Serve OpenAPI specification"""
    
    try:
        # In production, serve the actual OpenAPI spec from a file or CDN
        openapi_url = "https://raw.githubusercontent.com/your-org/copilot-plugin/main/plugins/openapi.yaml"
        
        # For now, return a redirect or the spec content
        return func.HttpResponse(
            f"OpenAPI specification available at: {openapi_url}",
            status_code=200,
            headers={'Content-Type': 'text/plain'}
        )
        
    except Exception as e:
        telemetry.track_exception(e, {'endpoint': 'openapi'})
        return func.HttpResponse(
            "OpenAPI specification not available",
            status_code=500,
            headers={'Content-Type': 'text/plain'}
        )
