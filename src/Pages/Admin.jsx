import { useEffect, useState } from "react";
import Navbar from "../components/Navbar";
import CarArt from "../components/CarArt";
import { carsAPI, usersAPI } from "../services/api";
import { useAuth } from "../AuthContext";
import { useLanguage } from "../i18n";

const EMPTY = { brand: "", type: "Sedan", pricePerDay: "", available: "" };
const TYPES = ["Sedan", "SUV", "Truck", "EV"];

export default function Admin() {
  const { user } = useAuth();
  const { t } = useLanguage();
  const [tab, setTab] = useState("cars");
  const [cars, setCars] = useState([]);
  const [users, setUsers] = useState([]);
  const [form, setForm] = useState(EMPTY);
  const [editingId, setEditingId] = useState(null);
  const [msg, setMsg] = useState({ type: "", text: "" });
  const [busy, setBusy] = useState(false);

  const load = async () => {
    try {
      const [c, u] = await Promise.all([carsAPI.getAll(), usersAPI.getAll()]);
      setCars(c);
      setUsers(u);
    } catch (e) {
      setMsg({ type: "error", text: e.message });
    }
  };
  useEffect(() => {
    if (user?.role === "admin") load();
  }, [user]);

  if (user?.role !== "admin") {
    return (
      <div className="page-wrapper">
        <Navbar />
        <div className="page-content">
          <div className="empty-state">
            <div className="empty-state-title">{t("adminOnly")}</div>
          </div>
        </div>
      </div>
    );
  }

  const flash = (type, text) => setMsg({ type, text });
  const onChange = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const save = async (e) => {
    e.preventDefault();
    const payload = { ...form, pricePerDay: Number(form.pricePerDay), available: Number(form.available) };
    if (!payload.brand.trim() || !(payload.pricePerDay > 0) || !(payload.available >= 0) || form.available === "") {
      flash("error", t("fillAllFields"));
      return;
    }
    setBusy(true);
    try {
      if (editingId) await carsAPI.update(editingId, payload);
      else await carsAPI.create(payload);
      flash("success", editingId ? t("carUpdated") : t("carAdded"));
      setForm(EMPTY);
      setEditingId(null);
      await load();
    } catch (err) {
      flash("error", err.message);
    } finally {
      setBusy(false);
    }
  };

  const edit = (car) => {
    setEditingId(car.id);
    setForm({ brand: car.brand, type: car.type, pricePerDay: String(car.pricePerDay), available: String(car.available) });
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const removeCar = async (car) => {
    if (!window.confirm(`${t("confirmDeleteCar")} ${car.brand}?`)) return;
    try {
      await carsAPI.remove(car.id);
      flash("success", t("carDeleted"));
      await load();
    } catch (err) {
      flash("error", err.message);
    }
  };

  const toggleRole = async (u) => {
    try {
      await usersAPI.updateRole(u.id, u.role === "admin" ? "user" : "admin");
      await load();
    } catch (err) {
      flash("error", err.message);
    }
  };

  const removeUser = async (u) => {
    if (!window.confirm(`${t("confirmDeleteUser")} ${u.username}?`)) return;
    try {
      await usersAPI.remove(u.id);
      await load();
    } catch (err) {
      flash("error", err.message);
    }
  };

  return (
    <div className="page-wrapper">
      <Navbar />
      <div className="page-content">
        <div className="page-header">
          <h1 className="page-title">{t("adminPanel")}</h1>
          <p className="page-subtitle">{t("adminPanelDesc")}</p>
        </div>

        <div className="admin-tabs" role="tablist">
          <button role="tab" aria-selected={tab === "cars"} className={tab === "cars" ? "active" : ""} onClick={() => setTab("cars")}>
            {t("manageCars")} ({cars.length})
          </button>
          <button role="tab" aria-selected={tab === "users"} className={tab === "users" ? "active" : ""} onClick={() => setTab("users")}>
            {t("manageUsers")} ({users.length})
          </button>
        </div>

        {msg.text && <div className={`alert alert-${msg.type === "error" ? "error" : "success"}`}>{msg.text}</div>}

        {tab === "cars" && (
          <>
            <form className="admin-form" onSubmit={save}>
              <h2 className="section-title">{editingId ? `${t("editCar")} #${editingId}` : t("addCar")}</h2>
              <div className="admin-form-grid">
                <label>
                  {t("brand")}
                  <input className="form-input" name="brand" value={form.brand} onChange={onChange} placeholder="Toyota Yaris" />
                </label>
                <label>
                  {t("type")}
                  <select className="form-input" name="type" value={form.type} onChange={onChange}>
                    {[...new Set([...TYPES, form.type])].map((x) => (
                      <option key={x}>{x}</option>
                    ))}
                  </select>
                </label>
                <label>
                  {t("pricePerDay")} (฿)
                  <input className="form-input" name="pricePerDay" type="number" min="1" value={form.pricePerDay} onChange={onChange} />
                </label>
                <label>
                  {t("stock")}
                  <input className="form-input" name="available" type="number" min="0" value={form.available} onChange={onChange} />
                </label>
              </div>
              <div className="admin-form-actions">
                <button className="btn-accent" type="submit" disabled={busy}>
                  {editingId ? t("saveChanges") : t("addCar")}
                </button>
                {editingId && (
                  <button type="button" className="btn-ghost" onClick={() => { setEditingId(null); setForm(EMPTY); }}>
                    {t("cancel")}
                  </button>
                )}
              </div>
            </form>

            <div className="admin-table-wrap">
              <table className="admin-table">
                <thead>
                  <tr>
                    <th></th><th>{t("brand")}</th><th>{t("type")}</th><th>{t("pricePerDay")}</th><th>{t("stock")}</th><th></th>
                  </tr>
                </thead>
                <tbody>
                  {cars.map((c) => (
                    <tr key={c.id}>
                      <td className="admin-thumb"><CarArt type={c.type} id={c.id} /></td>
                      <td><b>{c.brand}</b></td>
                      <td>{c.type}</td>
                      <td>฿{Number(c.pricePerDay).toLocaleString()}</td>
                      <td>{c.available}</td>
                      <td className="admin-actions">
                        <button className="btn-ghost btn-sm" onClick={() => edit(c)}>{t("edit")}</button>
                        <button className="btn-danger-outline btn-sm" onClick={() => removeCar(c)}>{t("delete")}</button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}

        {tab === "users" && (
          <div className="admin-table-wrap">
            <table className="admin-table">
              <thead>
                <tr><th>ID</th><th>{t("username")}</th><th>{t("role")}</th><th></th></tr>
              </thead>
              <tbody>
                {users.map((u) => (
                  <tr key={u.id}>
                    <td>{u.id}</td>
                    <td><b>{u.username}</b>{u.id === user.id && ` (${t("you")})`}</td>
                    <td><span className={`badge ${u.role === "admin" ? "badge-admin" : "badge-available"}`}>{u.role}</span></td>
                    <td className="admin-actions">
                      {u.id !== user.id && (
                        <>
                          <button className="btn-ghost btn-sm" onClick={() => toggleRole(u)}>
                            {u.role === "admin" ? t("makeUser") : t("makeAdmin")}
                          </button>
                          <button className="btn-danger-outline btn-sm" onClick={() => removeUser(u)}>{t("delete")}</button>
                        </>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
