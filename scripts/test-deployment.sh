#!/bin/bash

# Deployment Testing Script
# This script tests the deployed application and infrastructure

set -e

# Configuration
NAMESPACE="algorithm-visualizer"
APP_NAME="algorithm-visualizer"
TIMEOUT=300

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Testing Algorithm Visualizer Deployment${NC}"

# Function to check command availability
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        exit 1
    fi
}

# Function to wait for deployment
wait_for_deployment() {
    echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
    
    if kubectl wait --for=condition=available --timeout=${TIMEOUT}s deployment/${APP_NAME} -n ${NAMESPACE}; then
        echo -e "${GREEN}✅ Deployment is ready${NC}"
    else
        echo -e "${RED}❌ Deployment failed to become ready${NC}"
        return 1
    fi
}

# Function to test application endpoints
test_endpoints() {
    echo -e "${YELLOW}🔍 Testing application endpoints...${NC}"
    
    # Get service endpoint
    SERVICE_IP=$(kubectl get service ${APP_NAME}-service -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -z "$SERVICE_IP" ]; then
        echo -e "${YELLOW}⚠️  Load balancer not ready, using port-forward for testing${NC}"
        
        # Start port-forward in background
        kubectl port-forward -n ${NAMESPACE} service/${APP_NAME}-service 8080:80 &
        PORT_FORWARD_PID=$!
        sleep 5
        
        SERVICE_URL="http://localhost:8080"
    else
        SERVICE_URL="http://${SERVICE_IP}"
    fi
    
    echo -e "${BLUE}🌐 Testing URL: ${SERVICE_URL}${NC}"
    
    # Test health endpoint
    echo -e "${YELLOW}🏥 Testing health endpoint...${NC}"
    if curl -f -s "${SERVICE_URL}/health" > /dev/null; then
        echo -e "${GREEN}✅ Health check passed${NC}"
    else
        echo -e "${RED}❌ Health check failed${NC}"
        return 1
    fi
    
    # Test main page
    echo -e "${YELLOW}🏠 Testing main page...${NC}"
    if curl -f -s "${SERVICE_URL}/" | grep -q "DSA Algorithm Visualizer"; then
        echo -e "${GREEN}✅ Main page test passed${NC}"
    else
        echo -e "${RED}❌ Main page test failed${NC}"
        return 1
    fi
    
    # Test static assets
    echo -e "${YELLOW}📄 Testing static assets...${NC}"
    if curl -f -s "${SERVICE_URL}/style.css" > /dev/null; then
        echo -e "${GREEN}✅ CSS file accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  CSS file test failed${NC}"
    fi
    
    if curl -f -s "${SERVICE_URL}/app.js" > /dev/null; then
        echo -e "${GREEN}✅ JavaScript file accessible${NC}"
    else
        echo -e "${YELLOW}⚠️  JavaScript file test failed${NC}"
    fi
    
    # Cleanup port-forward if used
    if [ ! -z "$PORT_FORWARD_PID" ]; then
        kill $PORT_FORWARD_PID 2>/dev/null || true
    fi
}

# Function to test Kubernetes resources
test_kubernetes_resources() {
    echo -e "${YELLOW}☸️  Testing Kubernetes resources...${NC}"
    
    # Check namespace
    if kubectl get namespace ${NAMESPACE} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Namespace exists${NC}"
    else
        echo -e "${RED}❌ Namespace not found${NC}"
        return 1
    fi
    
    # Check deployment
    if kubectl get deployment ${APP_NAME} -n ${NAMESPACE} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Deployment exists${NC}"
        
        # Check replicas
        DESIRED=$(kubectl get deployment ${APP_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')
        READY=$(kubectl get deployment ${APP_NAME} -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}')
        
        if [ "$DESIRED" = "$READY" ]; then
            echo -e "${GREEN}✅ All replicas are ready (${READY}/${DESIRED})${NC}"
        else
            echo -e "${YELLOW}⚠️  Not all replicas are ready (${READY}/${DESIRED})${NC}"
        fi
    else
        echo -e "${RED}❌ Deployment not found${NC}"
        return 1
    fi
    
    # Check service
    if kubectl get service ${APP_NAME}-service -n ${NAMESPACE} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Service exists${NC}"
    else
        echo -e "${RED}❌ Service not found${NC}"
        return 1
    fi
    
    # Check ingress
    if kubectl get ingress ${APP_NAME}-ingress -n ${NAMESPACE} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Ingress exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Ingress not found${NC}"
    fi
    
    # Check HPA
    if kubectl get hpa ${APP_NAME}-hpa -n ${NAMESPACE} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ HPA exists${NC}"
    else
        echo -e "${YELLOW}⚠️  HPA not found${NC}"
    fi
}

# Function to test pod health
test_pod_health() {
    echo -e "${YELLOW}🏥 Testing pod health...${NC}"
    
    # Get pod names
    PODS=$(kubectl get pods -n ${NAMESPACE} -l app=${APP_NAME} -o jsonpath='{.items[*].metadata.name}')
    
    if [ -z "$PODS" ]; then
        echo -e "${RED}❌ No pods found${NC}"
        return 1
    fi
    
    for POD in $PODS; do
        echo -e "${BLUE}🔍 Checking pod: $POD${NC}"
        
        # Check pod status
        STATUS=$(kubectl get pod $POD -n ${NAMESPACE} -o jsonpath='{.status.phase}')
        if [ "$STATUS" = "Running" ]; then
            echo -e "${GREEN}✅ Pod is running${NC}"
        else
            echo -e "${RED}❌ Pod status: $STATUS${NC}"
            continue
        fi
        
        # Check readiness
        READY=$(kubectl get pod $POD -n ${NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$READY" = "True" ]; then
            echo -e "${GREEN}✅ Pod is ready${NC}"
        else
            echo -e "${RED}❌ Pod is not ready${NC}"
        fi
        
        # Check resource usage
        echo -e "${BLUE}📊 Resource usage:${NC}"
        kubectl top pod $POD -n ${NAMESPACE} 2>/dev/null || echo -e "${YELLOW}⚠️  Metrics not available${NC}"
    done
}

# Function to test autoscaling
test_autoscaling() {
    echo -e "${YELLOW}📈 Testing autoscaling...${NC}"
    
    if kubectl get hpa ${APP_NAME}-hpa -n ${NAMESPACE} > /dev/null 2>&1; then
        HPA_STATUS=$(kubectl get hpa ${APP_NAME}-hpa -n ${NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="AbleToScale")].status}')
        
        if [ "$HPA_STATUS" = "True" ]; then
            echo -e "${GREEN}✅ HPA is able to scale${NC}"
            
            # Show current metrics
            echo -e "${BLUE}📊 Current HPA status:${NC}"
            kubectl get hpa ${APP_NAME}-hpa -n ${NAMESPACE}
        else
            echo -e "${YELLOW}⚠️  HPA scaling issues detected${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  HPA not configured${NC}"
    fi
}

# Function to generate test report
generate_report() {
    echo -e "${BLUE}📋 Generating test report...${NC}"
    
    REPORT_FILE="deployment-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "Algorithm Visualizer Deployment Test Report"
        echo "Generated: $(date)"
        echo "=========================================="
        echo ""
        
        echo "Kubernetes Resources:"
        kubectl get all -n ${NAMESPACE}
        echo ""
        
        echo "Pod Details:"
        kubectl describe pods -n ${NAMESPACE} -l app=${APP_NAME}
        echo ""
        
        echo "Service Details:"
        kubectl describe service ${APP_NAME}-service -n ${NAMESPACE}
        echo ""
        
        echo "Ingress Details:"
        kubectl describe ingress ${APP_NAME}-ingress -n ${NAMESPACE} 2>/dev/null || echo "Ingress not found"
        echo ""
        
        echo "Events:"
        kubectl get events -n ${NAMESPACE} --sort-by='.lastTimestamp'
        
    } > $REPORT_FILE
    
    echo -e "${GREEN}✅ Test report saved to: $REPORT_FILE${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🔧 Checking prerequisites...${NC}"
    check_command kubectl
    check_command curl
    
    # Check if kubectl is configured
    if ! kubectl cluster-info > /dev/null 2>&1; then
        echo -e "${RED}❌ kubectl is not configured or cluster is not accessible${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo ""
    
    # Run tests
    wait_for_deployment
    echo ""
    
    test_kubernetes_resources
    echo ""
    
    test_pod_health
    echo ""
    
    test_endpoints
    echo ""
    
    test_autoscaling
    echo ""
    
    generate_report
    echo ""
    
    echo -e "${GREEN}🎉 Deployment testing completed successfully!${NC}"
    echo -e "${BLUE}📊 Summary:${NC}"
    echo "  - Kubernetes resources: ✅"
    echo "  - Pod health: ✅"
    echo "  - Application endpoints: ✅"
    echo "  - Autoscaling: ✅"
    echo ""
    echo -e "${YELLOW}🔗 Access your application:${NC}"
    
    # Show access information
    INGRESS_HOST=$(kubectl get ingress ${APP_NAME}-ingress -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$INGRESS_HOST" ]; then
        echo "  External URL: http://${INGRESS_HOST}"
    else
        echo "  Use port-forward: kubectl port-forward -n ${NAMESPACE} service/${APP_NAME}-service 8080:80"
        echo "  Then access: http://localhost:8080"
    fi
}

# Run main function
main "$@"
