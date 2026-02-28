# Vercel Deployment Guide - DRAIS Application

## Overview
This guide explains how to deploy the DRAIS application to Vercel with database connectivity to your MySQL database (ibunbaz_drais).

## Prerequisites
- Vercel account (sign up at https://vercel.com)
- Git repository (GitHub, GitLab, or Bitbucket)
- MySQL database hosting (e.g., Heroku, AWS RDS, DigitalOcean, or your own server)
- MySQL credentials for ibunbaz_drais database

## Step 1: Prepare Your Repository

### 1.1 Ensure .env.local is in .gitignore
Make sure your sensitive environment variables are not committed:

```bash
# Check if .gitignore exists and contains .env.local
cat .gitignore | grep ".env.local"
```

If not, add it:
```bash
echo ".env.local" >> .gitignore
```

### 1.2 Commit Your Changes
```bash
git add .
git commit -m "Configure database for ibunbaz_drais and prepare for Vercel deployment"
git push origin main
```

## Step 2: Initial Setup on Vercel

### 2.1 Import Project to Vercel
1. Go to https://vercel.com/new
2. Select your Git provider (GitHub, GitLab, GitBucket)
3. Find and select your DRAIS repository
4. Click "Import"

### 2.2 Configure Build Settings
On the import page, Vercel should auto-detect Next.js:
- **Framework Preset**: Next.js
- **Build Command**: `next build`
- **Output Directory**: `.next`
- **Install Command**: `npm install`

Click "Deploy" to proceed to the next step.

## Step 3: Set Environment Variables

### 3.1 Add Environment Variables to Vercel

After deployment starts, you'll see the environment variables section. Add the following variables:

#### Database Configuration
```
MYSQL_HOST = your-db-host.com
MYSQL_PORT = 3306
MYSQL_USER = your-db-username
MYSQL_PASSWORD = your-db-password
MYSQL_DB = ibunbaz_drais

# Alternative variables (for compatibility)
DB_HOST = your-db-host.com
DB_PORT = 3306
DB_USER = your-db-username
DB_PASS = your-db-password
DB_NAME = ibunbaz_drais
```

#### Application Configuration
```
NEXT_PUBLIC_APP_NAME = DRAIS
NEXT_PUBLIC_APP_URL = https://your-project.vercel.app

NODE_ENV = production

# Generate secure secrets (use: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
JWT_SECRET = your-secure-random-string
REFRESH_SECRET = your-secure-random-string
ENCRYPTION_KEY = your-32-char-hex-string
ADMIN_SECRET = your-secure-admin-secret
```

#### Optional Configuration
```
SMTP_HOST = smtp.gmail.com
SMTP_PORT = 587
SMTP_USER = your-email@gmail.com
SMTP_PASS = your-app-password
SMS_API_KEY = your-api-key
WHATSAPP_API_KEY = your-api-key
```

**Important**: Never share your credentials in version control or public places.

## Step 4: Database Setup on Vercel

### 4.1 Prepare Your Database for Remote Access

Your MySQL database must be accessible from Vercel servers. Options:

**Option A: Cloud Database (Recommended)**
- AWS RDS
- DigitalOcean Databases
- PlanetScale
- Azure Database for MySQL
- Heroku Cleardb (deprecated but may still work)

**Option B: Self-hosted with Public IP**
- Configure firewall to allow Vercel server IPs
- Vercel servers use dynamic IPs, consider allowing 0.0.0.0/0 with strong password

### 4.2 Import Schema to Production Database

Before your first deployment, import the schema:

```bash
# Local import (if your database is locally accessible)
npm run import:schema

# Or use MySQL CLI directly
mysql -h your-db-host.com -u your-username -p your-database-name < DraisIbunBaz_schema.sql
```

If your database is only accessible from specific servers:
1. Connect to your database hosting provider's interface
2. Use their web-based SQL editor to import the schema
3. Or use a bastion host/jump server to run the import

## Step 5: Deploy and Test

### 5.1 Complete Deployment
1. Click "Deploy" to finalize deployment
2. Wait for build completion (usually 2-5 minutes)
3. Navigate to your project URL

### 5.2 Test Database Connection
```bash
# Check logs for database connection errors
# In Vercel dashboard: Deployments > [Latest] > Logs

# Test API endpoint that uses database
curl https://your-project.vercel.app/api/health
```

### 5.3 Troubleshooting Connection Issues

If you get database connection errors:

1. **Check environment variables**: Vercel Dashboard > Settings > Environment Variables
   - Verify all required variables are set
   - Ensure no typos in variable names

2. **Check database accessibility**:
   ```bash
   # From your local machine
   mysql -h your-db-host.com -u your-username -p your-database-name
   # Should connect successfully
   ```

3. **Check database charset**:
   - Your schema uses utf8mb4
   - Ensure database supports it

4. **Check credentials**:
   - User has correct permissions
   - Password contains no special characters that need escaping

5. **Review Vercel logs**:
   - Deployments > [Your deployment] > Logs
   - Look for connection error messages

## Step 6: Configure Custom Domain (Optional)

1. Go to Vercel Dashboard > Settings > Domains
2. Add your custom domain
3. Update DNS records as instructed
4. Configure SSL (automatic via Vercel)

## Step 7: Set Up CI/CD and Auto-deployments

1. Vercel automatically deploys when you push to your main branch
2. Create preview deployments for pull requests
3. Vercel Dashboard > Settings > Git > Production Branch (usually `main`)

## Step 8: Ongoing Maintenance

### Regular Tasks
```bash
# Update environment variables if credentials change
# Vercel Dashboard > Settings > Environment Variables

# Monitor application
# Vercel Dashboard > Logs > Runtime logs

# Check database performance
# Your database provider's admin panel
```

### Database Updates
If you need to update the schema after deployment:

```bash
# Create a new migration file
# Place in database/ folder

# Apply migration:
mysql -h your-db-host.com -u your-username -p your-database-name < database/migration.sql

# Or through your database provider's web interface
```

## Database Connection String Reference

For services that require a connection string format:

```
mysql://username:password@host:port/database_name
mysql://your-username:your-password@your-db-host.com:3306/ibunbaz_drais
```

## Security Best Practices

1. **Never commit .env.local**: Add to .gitignore
2. **Use strong passwords**: Minimum 16 characters with mixed case, numbers, symbols
3. **Limit database user permissions**: Grant only necessary privileges
4. **Rotate credentials regularly**: Update passwords every 3-6 months
5. **Monitor access logs**: Check database access from unexpected IPs
6. **Use SSL/TLS**: Enable encrypted connections to database
7. **Keep secrets in Vercel only**: Use Vercel environment variables, not in code

## Help and Support

### Common Issues
- Connection timeout: Check database is accessible from internet
- Authentication failed: Verify username/password
- Database selected/doesn't exist: Check DB_NAME environment variable
- Table not found: Run import:schema script

### Resources
- Vercel Docs: https://vercel.com/docs
- Next.js Docs: https://nextjs.org/docs
- MySQL Docs: https://dev.mysql.com/doc/

### Quick Links
- Vercel Dashboard: https://vercel.com/dashboard
- GitHub Repository: [Your repo URL]
- Database Provider Dashboard: [Your hosting provider URL]

## Rollback Instructions

If deployment causes issues:

1. Vercel Dashboard > Deployments
2. Find previous working deployment
3. Click the menu (⋮) and select "Promote to Production"
4. This reverts to the previous version

## Next Steps

1. ✅ Set environment variables in Vercel
2. ✅ Import database schema
3. ✅ Test database connectivity
4. ✅ Monitor deployment logs
5. ✅ Celebrate your deployment! 🎉

---

**Last Updated**: February 28, 2026
**DRAIS Version**: 0.0.0036
**Database**: ibunbaz_drais
