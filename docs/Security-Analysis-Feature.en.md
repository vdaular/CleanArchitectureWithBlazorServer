# Account Security Analysis Feature

## Overview

The account security analysis feature analyzes user login history data to detect potential security threats and provide corresponding security recommendations. This feature helps identify whether an account has a risk of being compromised and promptly alerts users to take security measures.

## Feature Characteristics

### Security Threat Detection

The system detects the following types of security threats:

1. **New IP Address Login** - Detects logins from never-before-seen IP addresses
2. **Suspicious Geographic Location** - Detects logins from abnormal geographic locations
3. **Multiple Login Failures** - Detects password brute force attack attempts
4. **Abnormal Login Time** - Detects abnormal logins late at night or early morning
5. **New Device Login** - Detects logins from new devices/browsers
6. **Concurrent Sessions** - Detects simultaneous logins from multiple locations
7. **Rapid Geographic Movement** - Detects physically impossible rapid geographic location changes

### Risk Levels

The system defines four risk levels:

- **Low Risk (Low)** - No obvious security threats
- **Medium Risk (Medium)** - Some suspicious activities exist, attention recommended
- **High Risk (High)** - Obvious security threats detected, immediate action recommended
- **Critical Risk (Critical)** - Serious security threats detected, urgent handling required

## Usage Instructions

### 1. View Security Summary

In the "Login History" tab of the user profile page, security warning prompts will be displayed if security risks are detected.

### 2. Detailed Security Analysis

1. Visit the user profile page
2. Click the "Security Analysis" tab
3. Configure analysis parameters:
   - Analysis period (1-365 days)
   - Whether to include failed login analysis
4. Click the "Run Detailed Security Analysis" button

### 3. View Analysis Results

After analysis completion, the system will display:

- **Security Summary** - Overall risk level and key indicators
- **Detected Security Threats** - Specific threat types and details
- **Security Recommendations** - Processing recommendations for detected threats

## API Usage

### Analyze Account Security

```csharp
var query = new AnalyzeAccountSecurityQuery
{
    UserId = "user-id",
    AnalysisPeriodDays = 30,
    IncludeFailedLogins = true
};

var result = await mediator.Send(query);
```

### Get Security Summary

```csharp
var query = new GetSecuritySummaryQuery
{
    UserId = "user-id"
};

var result = await mediator.Send(query);
```

## Configuration Parameters

### Risk Scoring Rules

- New IP addresses: Medium risk (>3 IPs for high risk)
- Login failures: 5+ times for high risk, 10+ times for critical risk
- New devices: 2+ for high risk
- Rapid geographic movement: Cross-regional within 4 hours for high risk

### Caching Strategy

- Security summary cache: 5 minutes
- Detailed analysis cache: 10 minutes
- Cache tag: loginaudits

## Security Recommendations

Based on detected threat types, the system provides the following recommendations:

1. **Change Password Immediately** - When medium or higher risk is detected
2. **Enable Two-Factor Authentication** - Strengthen account security
3. **Check Recent Login Activity** - Verify all activities are authorized
4. **Monitor Brute Force Attacks** - Consider temporary IP blocking
5. **Log Out from All Devices** - Re-login only from trusted devices
6. **Contact System Administrator** - For critical risk situations

## Extended Features

### Custom Threat Detection Rules

Threat detection rules can be customized by modifying the analysis methods in `AnalyzeAccountSecurityQueryHandler`.

### Integration with External Threat Intelligence

Third-party threat intelligence APIs can be integrated to enhance risk assessment for IP addresses and geographic locations.

### Automated Response

Automated responses can be implemented based on risk levels, such as:
- Automatically lock high-risk accounts
- Send security warning emails
- Trigger administrator notifications

## Important Notes

1. This feature requires sufficient historical login data for effective analysis
2. Initial use may generate false alarms for some normal new devices or IP addresses
3. Geographic location detection is based on IP addresses and may have some inaccuracy
4. Regular security analysis is recommended to maintain account security 