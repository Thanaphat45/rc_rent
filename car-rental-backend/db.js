import dotenv from "dotenv";

dotenv.config();

// Two back ends, same API:
//  - DATABASE_URL set  -> PostgreSQL (Supabase); procedures are SQL functions in schema `driverent`
//  - otherwise         -> MySQL/MariaDB stored procedures (local docker compose, own MySQL)
const usePg = Boolean(process.env.DATABASE_URL);

let pgPool = null;
let mysqlPool = null;

if (usePg) {
  const { default: pg } = await import("pg");
  pgPool = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.DB_SSL === "false" ? false : { rejectUnauthorized: false },
    max: 5,
    options: `-c search_path=${process.env.DB_SCHEMA || "driverent"}`,
  });
} else {
  const { default: mysql } = await import("mysql2/promise");
  mysqlPool = mysql.createPool({
    host: process.env.DB_HOST || "localhost",
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "Rc Rent",
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });
}

export const query = async (sql, params = []) => {
  if (usePg) {
    const { rows } = await pgPool.query(sql, params);
    return rows;
  }
  const [rows] = await mysqlPool.query(sql, params);
  return rows;
};

export const callProcedure = async (procName, params = []) => {
  if (!/^sp_[a-z_]+$/.test(procName)) throw new Error("Invalid procedure name");
  if (usePg) {
    const placeholders = params.map((_, i) => `$${i + 1}`).join(",");
    const { rows } = await pgPool.query(`SELECT * FROM ${procName}(${placeholders})`, params);
    return rows;
  }
  const placeholders = params.map(() => "?").join(",");
  const [resultSets] = await mysqlPool.query(`CALL ${procName}(${placeholders})`, params);
  return resultSets[0] || [];
};

export default usePg ? pgPool : mysqlPool;
