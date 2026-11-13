import Navbar from "../components/Navbar";
import { Link } from "react-router-dom";
import { useState, useEffect } from "react";
import { carsAPI, rentalsAPI } from "../services/api";
import { useLanguage } from "../i18n";
import { useAuth } from "../AuthContext";
import CarCard from "../components/CarCard";
import CarArt from "../components/CarArt";

export default function Dashboard() {
  const [cars, setCars] = useState([]);
  const [rentals, setRentals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const { isAuthenticated } = useAuth();

  useEffect(() => {
    const fetchData = async () => {
      try {
        const carsData = await carsAPI.getAll();
        setCars(carsData);

        if (isAuthenticated) {
          const rentalsData = await rentalsAPI.getMyRentals();
          setRentals(rentalsData);
        }
      } catch (err) {
        setError(err.message || "Failed to load data");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [isAuthenticated]);

  const { t } = useLanguage();
  const totalCars = cars.length;
  const availableCars = cars.filter((c) => c.available > 0).length;
  const types = [...new Set(cars.map((c) => c.type))].length;
  const activeRentals = rentals.filter(r => r.status === "active").length;
  const completedRentals = rentals.filter(r => r.status === "completed").length;
  const heroCar = cars.find((c) => c.available > 0) || cars[0];

  return (
    <div className="page-wrapper">
      <Navbar />
      <div className="page-content">
        {error && <div className="alert alert-error">⚠️ {error}</div>}

        {loading ? (
          <div className="empty-state" style={{ marginTop: "60px" }}>
            <div className="empty-state-icon">⏳</div>
            <div className="empty-state-title">{t("loading")}</div>
          </div>
        ) : (
          <>
            <div className="dashboard-hero">
              {heroCar && <CarArt type={heroCar.type} id={heroCar.id} className="hero-car" />}
              <div className="hero-eyebrow">{t("carRentalPlatform")}</div>
              <h1 className="hero-title">{t("Welcome to Car Rental")}</h1>
              <p className="hero-desc">{t("rentYourCar")}</p>
              <div style={{ display: "flex", gap: "12px" }}>
                <Link to="/cars">
                  <button className="btn-accent btn-lg">{t("browseCars")}</button>
                </Link>
                <Link to="/my-rentals">
                  <button className="btn-ghost-light">{t("myRentals")}</button>
                </Link>
              </div>
              <div className="hero-stats" style={{ marginTop: "36px" }}>
                <div>
                  <div className="hero-stat-value">{totalCars}</div>
                  <div className="hero-stat-label">{t("totalCars")}</div>
                </div>
                <div>
                  <div className="hero-stat-value">{availableCars}</div>
                  <div className="hero-stat-label">{t("availableNow")}</div>
                </div>
                <div>
                  <div className="hero-stat-value">{types}</div>
                  <div className="hero-stat-label">{t("vehicleTypes")}</div>
                </div>
              </div>
            </div>

            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-card-icon">🚘</div>
                <div className="stat-card-value">{availableCars}</div>
                <div className="stat-card-label">{t("carsAvailable")}</div>
              </div>
              <div className="stat-card">
                <div className="stat-card-icon">📦</div>
                <div className="stat-card-value">{activeRentals}</div>
                <div className="stat-card-label">{t("activeRentals")}</div>
              </div>
              <div className="stat-card">
                <div className="stat-card-icon">✅</div>
                <div className="stat-card-value">{completedRentals}</div>
                <div className="stat-card-label">{t("completed")}</div>
              </div>
            </div>

            <div className="section-header">
              <h2 className="section-title">{t("featuredCars")}</h2>
              <Link to="/cars" style={{ fontSize: "14px", color: "var(--accent)", textDecoration: "none", fontWeight: "500" }}>
                {t("viewAll")}
              </Link>
            </div>

            <div className="car-grid">
              {cars.slice(0, 3).map((car) => <CarCard key={car.id} car={car} />)}
            </div>
          </>
        )}
      </div>
    </div>
  );
}