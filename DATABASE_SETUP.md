# Database Setup Guide for DRAIS (ibunbaz_drais)

## Quick Start

### 1. Environment Variables
Update `.env.local` in the project root:

```env
# MySQL Database
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=your-password
MYSQL_DB=ibunbaz_drais

# Fallback variables (optional, for compatibility)
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASS=your-password
DB_NAME=ibunbaz_drais
```

### 2. Create Database
```bash
# Using MySQL CLI
mysql -u root -p
> CREATE DATABASE IF NOT EXISTS ibunbaz_drais;
> EXIT;

# Or import schema directly
npm run import:schema
```

### 3. Import Schema
```bash
# Option 1: Using npm script (recommended)
npm run import:schema

# Option 2: Using MySQL CLI directly
mysql -u root -p ibunbaz_drais < DraisIbunBaz_schema.sql

# Option 3: Using mysql command with password inline (not recommended for security)
mysql -u root -p'your-password' ibunbaz_drais < DraisIbunBaz_schema.sql
```

### 4. Verify Installation
```bash
# Connect to database
mysql -u root -p ibunbaz_drais

# List all tables
SHOW TABLES;

# Count total tables (should be 50+)
SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='ibunbaz_drais';

# Check a sample table
DESCRIBE students;
```

## Database Configuration

### Supported Environment Variables

The application supports both sets of environment variables for flexibility:

| Variable | Alternative | Purpose | Default |
|----------|-------------|---------|---------|
| MYSQL_HOST | DB_HOST | Database host | localhost |
| MYSQL_PORT | DB_PORT | Database port | 3306 |
| MYSQL_USER | DB_USER | Database user | root |
| MYSQL_PASSWORD | DB_PASS | Database password | empty |
| MYSQL_DB | DB_NAME | Database name | ibunbaz_drais |

The application checks for both variable names, so you can use either set.

### Connection Details
- **Database Name**: ibunbaz_drais
- **Character Set**: utf8mb4
- **Collation**: utf8mb4_0900_ai_ci
- **Engine**: InnoDB (for transactions and foreign keys)
- **Total Tables**: 50+ tables
- **Total Indexes**: 100+

## Connection Pooling

The database connection uses a pool with the following settings:
- **Pool Size**: 10 connections
- **Queue Limit**: 0 (unlimited queue)
- **Keep Alive**: Enabled
- **Timezone**: UTC (Z)

This ensures efficient resource usage and automatic connection recycling.

## Schema Overview

The schema includes tables for:
- **Core**: students, users, schools, classes
- **Attendance**: daily_attendance, attendance_audit_logs
- **Academic**: academic_years, terms, subjects
- **Finance**: fees, payments, receipts
- **Promotions**: promotion_rules, promotion_history
- **Reports**: student_tahfiz_results, academic_reports
- And many more...

## Testing Database Connectivity

### Test from Node.js
```javascript
// src/lib/db.test.ts
import { query } from '@/lib/db';

async function testConnection() {
  try {
    const result = await query('SELECT 1 as test');
    console.log('✅ Database connection successful:', result);
  } catch (error) {
    console.error('❌ Database connection failed:', error);
  }
}
```

### Test from API Route
```typescript
// src/api/health/route.ts
import { query } from '@/lib/db';

export async function GET() {
  try {
    const result = await query('SELECT 1 as status');
    return Response.json({ 
      status: 'ok',
      database: 'connected'
    });
  } catch (error) {
    return Response.json({ 
      status: 'error',
      message: error.message
    }, { status: 500 });
  }
}
```

### Test from Command Line
```bash
# Test MySQL connection
mysql -h localhost -u root -p ibunbaz_drais -e "SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='ibunbaz_drais';"

# Test with Node script
node -e "require('mysql2/promise').createConnection({host: 'localhost', user: 'root', password: '', database: 'ibunbaz_drais'}).then(() => console.log('✅ Connected')).catch(e => console.log('❌ Failed:', e.message))"
```

## Troubleshooting

### "Cannot find module 'mysql2'"
```bash
npm install mysql2 dotenv
```

### "Access denied for user 'root'@'localhost'"
- Check password in .env.local is correct
- Verify MySQL user exists and has correct permissions
```bash
mysql -u root -p
> SELECT user, host FROM mysql.user;
```

### "Can't connect to MySQL server on 'localhost'"
- Ensure MySQL is running:
```bash
# Linux/Mac
sudo systemctl status mysql

# Windows
net start MySQL80
```

### "Unknown database 'ibunbaz_drais'"
- Create the database first:
```bash
npm run import:schema
# Or manually:
mysql -u root -p -e "CREATE DATABASE ibunbaz_drais;"
```

### Connection timeout on Vercel
- Check database is accessible from internet
- Verify database host is publicly accessible
- Check firewall allows port 3306
- Add Vercel IP range to database firewall whitelist:
  - For cloud databases, usually you can set "Allow all" or add specific IPs
  - Contact your database provider for Vercel IP ranges

### Tables not found after import
- Verify schema was imported without errors
```bash
mysql -u root -p ibunbaz_drais -e "SHOW TABLES;"
```
- Re-import if needed:
```bash
npm run import:schema
```

## Development Workflow

### Running Locally
```bash
# 1. Install dependencies
npm install

# 2. Create/update .env.local with your database credentials
# See .env.example for reference

# 3. Ensure MySQL is running
# 4. Import schema (first time only)
npm run import:schema

# 5. Start development server
npm run dev

# 6. Visit http://localhost:3000
```

### Making Schema Changes
```bash
# 1. Create migration file in database/ folder
# database/migration_YYYYMMDD.sql

# 2. Apply migration
mysql -u root -p ibunbaz_drais < database/migration_YYYYMMDD.sql

# 3. Test locally
npm run dev

# 4. Commit and push changes
git add .
git commit -m "Add database migration"
git push
```

## Production Deployment

### Before Deploying to Vercel
1. ✅ Ensure database is publicly accessible or set up proper networking
2. ✅ Create production database: `ibunbaz_drais`
3. ✅ Run import script or import schema manually
4. ✅ Set environment variables in Vercel dashboard
5. ✅ Test connection from local machine to production database

### Vercel Environment Variables
In your Vercel dashboard, add:
```
MYSQL_HOST=your-prod-db-host.com
MYSQL_PORT=3306
MYSQL_USER=prod-db-user
MYSQL_PASSWORD=prod-db-password
MYSQL_DB=ibunbaz_drais
```

### Post-Deployment
1. Test API endpoints that use database
2. Monitor Vercel logs for connection errors
3. Check database access logs
4. Set up backups if using external database provider

## Performance Optimization

### Connection Pool Tuning
Edit `src/lib/db.ts` to adjust pool size based on traffic:
```typescript
connectionLimit: 10,  // Increase for high traffic: 20, 50, etc.
queueLimit: 0,        // 0 = unlimited queue
```

### Query Optimization
- Add indexes on frequently searched columns (already in schema)
- Use EXPLAIN to analyze slow queries:
```sql
EXPLAIN SELECT * FROM students WHERE status='active';
```

### Backup Strategy
For production databases:
```bash
# Manual backup
mysqldump -u root -p ibunbaz_drais > backup_$(date +%Y%m%d_%H%M%S).sql

# Automated backup (add to crontab)
0 2 * * * mysqldump -u root -p'password' ibunbaz_drais > /backups/ibunbaz_drais_$(date +\%Y\%m\%d).sql
```

## Additional Resources

- [MySQL Documentation](https://dev.mysql.com/doc/)
- [mysql2 NPM Package](https://npm.im/mysql2)
- [Next.js with MySQL](https://nextjs.org/docs/app/building-your-application/data-fetching)
- [Connection Pooling Best Practices](https://en.wikipedia.org/wiki/Connection_pool)

## Support

For issues related to:
- **Schema**: Check [VERCEL_DEPLOYMENT_GUIDE.md](./VERCEL_DEPLOYMENT_GUIDE.md)
- **Configuration**: Review [.env.example](./.env.example)
- **Scripts**: See `scripts/import-schema.js`
- **Code**: Check `src/lib/db.ts` for connection logic

---

**Last Updated**: February 28, 2026  
**Database Version**: ibunbaz_drais (DRAIS 0.0.0036)  
**MySQL Minimum Version**: 5.7  
**Recommended Version**: 8.0+
