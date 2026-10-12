import type { Metadata, Viewport } from "next";
import { Geist, Outfit } from "next/font/google";
import { Toaster } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const outfit = Outfit({
  variable: "--font-outfit",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "WordTrace: a daily word-path puzzle",
  description:
    "Trace hidden words through a grid of letters. Every tile is used exactly once. A new board every day.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
  themeColor: "#f6f1ea",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${geistSans.variable} ${outfit.variable} h-full antialiased`}>
      <body className="flex min-h-full flex-col bg-[#f6f1ea]">
        <TooltipProvider>{children}</TooltipProvider>
        <Toaster position="top-center" richColors closeButton={false} duration={2200} />
      </body>
    </html>
  );
}
