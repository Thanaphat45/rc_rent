import { Link, useLocation, useNavigate } from "react-router-dom";
import { useLanguage } from "../i18n";
import { useAuth } from "../AuthContext";
import "../App.css";

export default function Navbar() {
  const location = useLocation();
  const navigate = useNavigate();
  const { language, setLanguage, t } = useLanguage();
  const { user, logout } = useAuth();

  const isActive = (path) => location.pathname === path;
  const isAuthenticated = !!user;
  const isAdmin = user?.role === "admin";

  const handleLanguageToggle = () => {
    setLanguage(language === "en" ? "th" : "en");
  };

  const handleLogout = async () => {
    await logout();
    navigate("/login");
  };

  return (
    <nav className="navbar">
      <Link to="/" className="navbar-brand">
        <span className="navbar-brand-icon" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18" fill="#fff"><path d="M5 11l1.5-4.5A2 2 0 0 1 8.4 5h7.2a2 2 0 0 1 1.9 1.5L19 11a2 2 0 0 1 2 2v4h-2a2 2 0 1 1-4 0H9a2 2 0 1 1-4 0H3v-4a2 2 0 0 1 2-2zm2.1 0h9.8l-1.1-3.4a.5.5 0 0 0-.5-.3H8.7a.5.5 0 0 0-.5.3z"/></svg></span>
        DriveRent
      </Link>

      <div className="navbar-links">
        <Link to="/" className={isActive("/") ? "active" : ""}>{t("dashboard")}</Link>
        <Link to="/cars" className={isActive("/cars") ? "active" : ""}>{t("cars")}</Link>
        {isAuthenticated && (
          <>
            <Link to="/my-rentals" className={isActive("/my-rentals") ? "active" : ""}>{t("myRentals")}</Link>
            <Link to="/profile" className={isActive("/profile") ? "active" : ""}>{t("profile")}</Link>
          </>
        )}
        {isAdmin && (
          <span className="navbar-admin-badge">{t("admin")}</span>
        )}
      </div>

      <div className="navbar-auth">
        <button
          type="button"
          className="btn-language-toggle"
          onClick={handleLanguageToggle}
        >
          {language === "en" ? "ไทย" : "EN"}
        </button>
        {isAuthenticated ? (
          <button
            className="btn-outline"
            onClick={handleLogout}
            style={{ cursor: "pointer", border: "1px solid", padding: "8px 16px", borderRadius: "4px", background: "transparent" }}
          >
            {t("logout")}
          </button>
        ) : (
          <>
            <Link to="/login" className="btn-outline">{t("login")}</Link>
            <Link to="/register" className="btn-filled">{t("register")}</Link>
          </>
        )}
      </div>
    </nav>
  );
}