FROM openjdk:17-jdk-slim
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests
EXPOSE 8081
CMD ["java", "-jar", "target/app.jar"]