-- Kerala public holidays 2026 (Kerala Gazette, G.O.(P) No. 15/2025/GAD, 31 Oct 2025).
-- Holidays on a Sunday (Mahasivarathri 15 Feb, Easter 5 Apr, Deepavali 8 Nov) are left out, as in the
-- government list. * = depends on the moon: check the date nearer the time in Settings → General → Holidays.
-- Safe to run more than once; existing dates keep their names.
INSERT INTO holidays (day, name) VALUES
  ('2026-01-02', 'Mannam Jayanthi'),
  ('2026-01-26', 'Republic Day'),
  ('2026-03-20', 'Id-ul-Fitr (Ramzan) *'),
  ('2026-04-02', 'Maundy Thursday'),
  ('2026-04-03', 'Good Friday'),
  ('2026-04-14', 'Dr B R Ambedkar Jayanthi'),
  ('2026-04-15', 'Vishu'),
  ('2026-05-01', 'May Day'),
  ('2026-05-27', 'Id-ul-Adha (Bakrid) *'),
  ('2026-06-25', 'Muharram *'),
  ('2026-08-12', 'Karkidaka Vavu'),
  ('2026-08-15', 'Independence Day'),
  ('2026-08-25', 'First Onam / Milad-i-Sherif *'),
  ('2026-08-26', 'Thiruvonam'),
  ('2026-08-27', 'Third Onam'),
  ('2026-08-28', 'Fourth Onam / Sree Narayana Guru Jayanthi / Ayyankali Jayanthi'),
  ('2026-09-04', 'Sree Krishna Jayanthi'),
  ('2026-09-21', 'Sree Narayana Guru Samadhi'),
  ('2026-10-02', 'Gandhi Jayanthi'),
  ('2026-10-20', 'Mahanavami'),
  ('2026-10-21', 'Vijayadasami'),
  ('2026-12-25', 'Christmas')
ON CONFLICT (day) DO NOTHING;
