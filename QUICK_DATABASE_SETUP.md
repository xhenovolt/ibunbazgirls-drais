# Quick Database Setup Reference

## 5-Minute Setup

```bash
# 1. Edit .env.local with your database credentials
nano .env.local
# Update: MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD

# 2. Install dependencies
npm install

# 3. Import schema
npm run import:schema

# 4. Start development
npm run dev

# 5. Your app is now connected to ibunbaz_drais!
```

## Environment Variables

```env
# Minimum required
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=your-password
MYSQL_DB=ibunbaz_drais

# Optional (Vercel production)
MYSQL_PORT=3306
NODE_ENV=production
```

## Common Commands

```bash
# Install dependencies
npm install

# Import database schema
npm run import:schema

# Start development server
npm run dev

# Build for production
npm build

# Start production server
npm start

# Run linter
npm lint

# Check database connection
mysql -u root -p ibunbaz_drais -e "SHOW TABLES;"

# Backup database
mysqldump -u root -p ibunbaz_drais > backup.sql

# Restore database
mysql -u root -p ibunbaz_drais < backup.sql
```

## Verify Setup

```bash
# Check connection (from project root)
node -e "require('./src/lib/db').getPool().execute('SELECT 1').then(() => console.log('✅ Connected')).catch(e => console.log('❌ Error:', e.message))"

# Check database exists
mysql -u root -p -e "SHOW DATABASES LIKE 'ibunbaz_drais';"

# Count tables
mysql -u root -p ibunbaz_drais -e "SHOW TABLES;" | wc -l

# Test API health (after npm run dev)
curl http://localhost:3000/api/health
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Module not found | `npm install` |
| Cannot connect | Check MySQL is running, verify credentials |
| Database doesn't exist | `npm run import:schema` |
| Tables missing | `npm run import:schema` again |
| Wrong password | Edit `.env.local` and restart |
| Vercel connection fails | Set env vars in Vercel dashboard + ensure DB is public |

## For Vercel

1. Set environment variables in Vercel dashboard:
   - MYSQL_HOST
   - MYSQL_USER
   - MYSQL_PASSWORD
   - MYSQL_DB=ibunbaz_drais

2. Ensure database is publicly accessible

3. Import schema before deployment:
   ```bash
   mysql -h your-db-host -u user -p ibunbaz_drais < DraisIbunBaz_schema.sql
   ```

## Files Modified

- ✅ `.env.local` - Updated database name to ibunbaz_drais
- ✅ `.env.example` - Updated template
- ✅ `src/lib/db.ts` - Enhanced connection pooling
- ✅ `package.json` - Added dotenv dependency and import:schema script
- ✅ `scripts/import-schema.js` - Automated schema import
- ✅ Multiple documentation files added

## Detailed Guides

- **Setup**: [DATABASE_SETUP.md](./DATABASE_SETUP.md)
- **Vercel**: [VERCEL_DEPLOYMENT_GUIDE.md](./VERCEL_DEPLOYMENT_GUIDE.md)
- **Changes**: [DATABASE_CONFIG_CHANGES.md](./DATABASE_CONFIG_CHANGES.md)

---

**Ready to go!** 🚀
