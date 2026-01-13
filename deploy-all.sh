#!/bin/bash

# הגדרת משתנים
PROJECT_ID="shay-project-477811"
CLUSTER_NAME="shay-project-cluster"
REGION="us-central1"

echo "🚀 מתחיל פריסה אוטומטית של Shay Project..."

# 1. יצירת הקלאסטר
echo "🏗️ מקים את הקלאסטר (זה עשוי לקחת כמה דקות)..."
gcloud container clusters list --format="value(name)" | grep -q "^$CLUSTER_NAME$" || gcloud container clusters create-auto $CLUSTER_NAME --region $REGION --project $PROJECT_ID
# 2. חיבור ה-kubectl
echo "🔗 מחבר את הטרמינל לקלאסטר..."
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

# 3. יצירת סודות (Secrets)
echo "🔑 מגדיר סודות..."
# מחיל את קובץ הסודות המרכזי שיצרנו (DB ו-OpenAI)
kubectl apply -f k8s/secrets.yaml

# יוצר את הסוד עבור המפתח של Google Cloud (הקובץ הפיזי שחייב להיות בתיקייה)
if [ -f "sql-key.json" ]; then
    kubectl create secret generic sql-key-secret --from-file=service_account.json=sql-key.json --dry-run=client -o yaml | kubectl apply -f -
else
    echo "❌ שגיאה: קובץ sql-key.json לא נמצא בתיקייה!"
    exit 1
fi

# 4. הגדרת זהות (Workload Identity)
echo "🆔 מגדיר Workload Identity..."
kubectl create serviceaccount k8s-sql-sa --dry-run=client -o yaml | kubectl apply -f -
kubectl annotate serviceaccount k8s-sql-sa \
    iam.gke.io/gcp-service-account=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')-compute@developer.gserviceaccount.com \
    --overwrite

# 5. פריסת האפליקציה
echo "📦 פורס את כל רכיבי המערכת..."
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/certificate.yaml
kubectl apply -f k8s/ingress.yaml

echo "⏳ ממתין 30 שניות להקצאת משאבים..."
sleep 30
kubectl get ingress shay-project-ingress

echo "✅ הפריסה הושלמה!"
echo "🔗 בדוק את ה-IP ב-kubectl get ingress והדבק ב-GoDaddy."