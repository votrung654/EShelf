# Hướng Dẫn Compile Presentation LaTeX

## Yêu Cầu

1. **LaTeX Distribution:**
   - TeX Live (khuyến nghị) hoặc MiKTeX
   - Đảm bảo có đầy đủ packages

2. **Packages cần thiết:**
   - beamer
   - babel (với vietnamese)
   - tikz
   - listings
   - xcolor
   - graphicx
   - hyperref

## Cách Compile

### Cách 1: Sử dụng pdflatex (khuyến nghị)

```bash
pdflatex Nhom15-NT548_Q11_PRESENTATION.tex
pdflatex Nhom15-NT548_Q11_PRESENTATION.tex  # Chạy lại lần 2 để fix references
```

### Cách 2: Sử dụng latexmk (tự động)

```bash
latexmk -pdf -pvc Nhom15-NT548_Q11_PRESENTATION.tex
```

### Cách 3: Sử dụng Overleaf (online)

1. Tạo project mới trên [Overleaf](https://www.overleaf.com)
2. Upload file `Nhom15-NT548_Q11_PRESENTATION.tex`
3. Compile tự động

## Cấu Trúc File

- `Nhom15-NT548_Q11_PRESENTATION.tex` - File LaTeX chính
- Output: `Nhom15-NT548_Q11_PRESENTATION.pdf`

## Lưu Ý

- File sử dụng theme `Madrid` của Beamer
- Aspect ratio: 16:9 (widescreen)
- Tất cả diagrams được vẽ bằng TikZ (không cần file ảnh ngoài)
- Nếu thiếu package, cài đặt qua package manager của LaTeX distribution

## Troubleshooting

### Lỗi: Package not found
```bash
# TeX Live
tlmgr install <package-name>

# MiKTeX
miktex install <package-name>
```

### Lỗi: Vietnamese babel
Đảm bảo đã cài đặt `babel-vietnamese`:
```bash
tlmgr install babel-vietnamese
```

### Lỗi: TikZ shapes
Các shapes đã được thay thế bằng rectangle để tương thích tốt hơn.

## Preview

Sau khi compile thành công, file PDF sẽ có:
- Title slide với thông tin nhóm
- Table of contents
- 5 sections chính với các diagrams:
  1. Infrastructure architecture (AWS + K3s)
  2. Microservices architecture
  3. CI/CD pipeline flow
  4. GitOps flow
  5. Monitoring stack






