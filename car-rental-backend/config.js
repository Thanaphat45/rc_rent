// Central place for secrets. In production a missing secret is a startup error,
// never a silent fallback that would let anyone forge login tokens.
const isProduction = process.env.NODE_ENV === "production";

export const JWT_SECRET = process.env.JWT_SECRET || (isProduction ? null : "dev-only-insecure-secret");

if (!JWT_SECRET || (isProduction && JWT_SECRET.length < 32)) {
  throw new Error("JWT_SECRET must be set (32+ characters) in production");
}
